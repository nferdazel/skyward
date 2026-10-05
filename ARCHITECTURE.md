# Arsitektur

Skyward web client — konsumen `skyward-api` (Go). Lihat juga
[`README.md`](README.md).

## Bentuk

Klien **statis murni**. Tidak ada SSR, tidak ada runtime Node di produksi.
Hasil build (`build/`) adalah kumpulan file yang diserve Caddy. Semua data
datang dari `skyward-api` lewat REST + WebSocket.

```
Browser ── HTTPS ──► skyward.qouver.com
                        ├── /            → build/ (statis)
                        └── /skyward/*   → reverse_proxy skyward-api (Go)
```

## Lapisan

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
