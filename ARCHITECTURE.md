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
cmd/server/           Entrypoint, wiring service, worker
internal/engine/      Simulasi, ekonomi, armada, rute, bank, bot, world tick
internal/handler/     HTTP handler (thin glue)
internal/store/       Akses data (baca + tulis, termasuk normalisasi username)
internal/realtime/    WebSocket hub (subscribe dibatasi allowlist channel)
internal/middleware/  Auth, rate limit, trusted-proxy untuk IP klien
internal/httperr/     Envelope error + pemetaan status HTTP
internal/money/       Aturan uang & formula ekonomi bersama (pintu ledger)
internal/worker/      Loop world-tick (pengganti pg_cron) + retensi
internal/db/          Pool pgx + tracer query lambat
internal/build/       Info versi binary (ldflags)
internal/logfile/     Log harian `app-YYYY-MM-DD.log` + rotasi
internal/config/      Konfigurasi env
```

Aturan: engine berjalan dalam satu transaksi per mutasi; uang dibulatkan di
pintu ledger; server otoritatif untuk ekonomi. Refactor struktural wajib
paritas-perilaku: logika ekonomi tidak disentuh tanpa test yang mengunci
perilaku lamanya, dan test berbasis DB ikut dijalankan (`TEST_DATABASE_URL`,
serial — lihat Build & deploy).

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
src/lib/shell/       App-chrome (TopHud, NotificationPanel) — boleh tahu fitur
```

Aturan arah data: `ui → state → data → api`. Tidak pernah sebaliknya, dan
`ui/` tidak pernah memanggil `fetch` langsung.

**Pengecualian:** `core/di/` (container komposisi) dan `shell/` (app-chrome)
boleh mengetahui fitur — DI untuk merakit store dan gateway, shell untuk merakit
HUD/notifikasi dari store per-sesi. Ini peran komposisi, bukan infrastruktur
generik; komponen di `core/components/` tetap tidak boleh bergantung pada
`features/`.

## Prinsip

1. **FE tidak menghitung ekonomi.** Demand, harga, wear, kredit, saldo —
   semuanya otoritatif di server. Klien merender dan mengirim perintah.
2. **Realtime = lapisan kesegaran.** Event WebSocket memicu refetch REST; tidak
   menulis state domain secara langsung.
3. **Satu koneksi WebSocket** dibagi semua store; subscribe channel memakai
   ref-count agar satu store tidak melepas channel milik store lain.
4. **Static, tanpa SSR** — keputusan sadar (tidak ada kebutuhan SEO).

## Build & deploy

- **CI** (`.github/workflows/ci.yml`): Go (`vet`, `test`) + test DB + web
  (`check`, `lint`, `test`, `build`) + secret scan (gitleaks) pada tiap push/PR.
  Hanya verifikasi, tidak deploy.
- **Test DB wajib serial** (`go test -p 1 ./...`): seluruh paket berbagi satu
  database, dan `WorldTick` memproses pemain yang baru dibuat paket lain —
  paralel membuat tick memproses user yang sudah dihapus (flake).
- **Deploy**: GitHub webhook → `deploy/deploy-vps.sh` di VPS (pola sama dengan
  project Qouver lain). Build di VPS, tanpa registry, tanpa secret GitHub.
- **Gate migrasi**: skrip deploy tidak menerapkan DDL. Bila `migrations/` ikut
  berubah dan ada berkas yang belum tercatat di `schema_migrations` — atau isi
  berkas migrasi yang sudah diterapkan berubah — deploy ditolak sebelum API
  di-restart. Migrasi append-only: perbaikan selalu migrasi baru.

## Konfigurasi

Lihat `.env.example`. Nilai build-time:

| Variabel | Fungsi |
|---|---|
| `VITE_SKYWARD_API_URL` | Base URL `skyward-api` (dev `http://localhost:8090`) |

Nilai asli hanya di server. Tidak ada secret di repo.
