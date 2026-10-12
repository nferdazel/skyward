# Keamanan

Terima kasih sudah peduli. Repo ini publik dan memuat **backend Go (`apps/api`)
dan klien web (`apps/web`)** — termasuk fitur & skema game, bukan data pemain.

## Melaporkan

Temuan keamanan **jangan** lewat issue publik. Kirim email ke
`fredinix@proton.me` dengan langkah reproduksi. Direspons secepatnya.

## Cakupan

**Repo**

- Tidak ada rahasia di repo. Kredensial (`DATABASE_URL`, `JWT_SECRET`, secret
  webhook, deploy key) hanya ada di server dengan mode 600; yang di-commit hanya
  contoh berisi placeholder (`deploy/env/*.example`, `.env.example`).
- `gitleaks` memindai riwayat penuh di CI, dan `.env` di-gitignore.

**Klien web**

- Tidak menyimpan rahasia; ia bicara ke `skyward-api` dengan JWT milik pengguna.
- Token sesi ada di `localStorage` (klien statis, tidak ada cookie sesi server).
  XSS adalah risiko utama klien jenis ini: tidak ada `innerHTML` dari data
  server, dan dependensi dijaga minimal.

**API**

- Otorisasi per pemain: identitas diambil dari JWT, bukan dari parameter yang
  dikirim klien.
- Rate limit per IP + per username (window) dengan header `Retry-After`.
  `X-Forwarded-For`/`X-Real-IP` hanya dipercaya bila koneksi datang dari trusted
  proxy; `CF-Connecting-IP` **tidak** dipercaya — proxy Cloudflare belum aktif,
  jadi klien bisa memalsukan header itu untuk memutar key rate-limit.
- Login gagal tidak membocorkan apakah username terdaftar (pesan seragam), dan
  username dinormalkan sebelum dipakai.
- Migrasi append-only: gate deploy menolak push yang meninggalkan migrasi belum
  tercatat, atau yang mengubah isi migrasi yang sudah diterapkan.

## Praktik repo

- Dependencies di-update via Dependabot.
- Kode publik mengungkap fitur & skema game (demand, tarif, bot); ini
  konsekuensi sadar dari open-source, bukan kebocoran.

## Versi yang didukung

Proyek ini berjalan langsung dari branch `main` — tidak ada rilis bertag.
Produksi men-deploy `main`, dan perbaikan keamanan mendarat di sana; jadi versi
yang didukung adalah `main` terbaru.
