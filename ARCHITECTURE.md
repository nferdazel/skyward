# Arsitektur

Skyward — monorepo: backend `skyward-api` (Go) + klien web (SvelteKit).
Lihat juga [`README.md`](README.md).

## Bentuk

```
apps/api/    Backend Go (REST + WebSocket + engine simulasi + worker)
apps/web/    Klien SvelteKit statis (tanpa SSR)
migrations/  Migrasi SQL (dimiliki bersama, dijalankan `scripts/migrate.sh`)
deploy/      Kontrak deploy (skrip webhook, Caddy contoh, env contoh)
scripts/     Operasi DB (migrate, prune, backup, drift-check)
```

Server adalah otoritatif untuk seluruh ekonomi. Klien web merender dan
mengirim perintah.

```
Browser ── HTTPS ──► skyward.qouver.com
                        ├── /            → apps/web/build (statis)
                        └── /skyward/*   → reverse_proxy skyward-api (Go :8090)
```

## Backend (`apps/api`)

Modular monolith Go, satu binary (`cmd/server`) + worker tick in-process.

```
cmd/server/        Entrypoint, wiring service, worker
internal/engine/   Simulasi, ekonomi, armada, rute, bank, bot, world tick
internal/handler/  HTTP handler (thin glue)
internal/store/    Query baca
internal/realtime/ WebSocket hub
internal/middleware/ Auth, rate limit
internal/config/   Konfigurasi env
```

Aturan: engine berjalan dalam satu transaksi per mutasi; uang dibulatkan di
pintu ledger; server otoritatif untuk ekonomi. Refactor struktural harus
paritas-perilaku (lihat `docs/ARCHITECTURE.md` §3 untuk rencana B1–B7).

## Frontend (`apps/web`)

Klien statis murni. Tidak ada SSR, tidak ada runtime Node di produksi.

```
src/routes/          Halaman + guard auth (SvelteKit)
src/lib/core/        Infrastruktur lintas fitur
  api/               ApiClient (HTTP), token store, error envelope
  realtime/          WebSocket client (tiket sekali pakai, ref-count channel)
  sync/              Event bus internal
  config/            Env
  theme/             Token warna/spacing/typography (design system)
  utils/             Formatter, helper
  components/        Komponen UI generik
src/lib/features/    Satu folder per fitur
  <feature>/data/     Gateway (satu-satunya yang tahu endpoint)
  <feature>/domain/   Tipe & mapper (murni, tanpa I/O)
  <feature>/state/    Store (pemilik state)
  <feature>/ui/       Komponen (baca store, panggil aksi)
```

Aturan arah data: `ui → state → data → api`. Tidak pernah sebaliknya, dan
`ui/` tidak pernah memanggil `fetch` langsung.

**Satu-satunya pengecualian:** `core/di/` (container komposisi) boleh mengetahui
semua fitur untuk merakit store dan gateway. Ini peran DI container, bukan
infrastruktur generik; komponen di `core/components/` tetap tidak boleh
bergantung pada `features/`.

## Prinsip

1. **FE tidak menghitung ekonomi.** Demand, harga, wear, kredit, saldo —
   semuanya otoritatif di server. Klien merender dan mengirim perintah.
2. **Realtime = lapisan kesegaran.** Event WebSocket memicu refetch REST; tidak
   menulis state domain secara langsung.
3. **Satu koneksi WebSocket** dibagi semua store; subscribe channel memakai
   ref-count agar satu store tidak melepas channel milik store lain.
4. **Static, tanpa SSR** — keputusan sadar (tidak ada kebutuhan SEO).

## Build & deploy

- **CI** (`.github/workflows/ci.yml`): `check`, `lint`, `test`, `build` pada
  tiap push/PR. Hanya verifikasi, tidak deploy.
- **Deploy**: GitHub webhook → `deploy/deploy-vps.sh` di VPS (pola sama dengan
  project Qouver lain). Build di VPS, tanpa registry, tanpa secret GitHub.

## Konfigurasi

Lihat `.env.example`. Nilai build-time:

| Variabel | Fungsi |
|---|---|
| `VITE_SKYWARD_API_URL` | Base URL `skyward-api` (dev `http://localhost:8090`) |

Nilai asli hanya di server. Tidak ada secret di repo.
