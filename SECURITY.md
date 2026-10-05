# Keamanan

Terima kasih sudah peduli. Repo ini publik dan kode klien.

## Melaporkan

Temuan keamanan **jangan** lewat issue publik. Kirim email ke
`fredinix@proton.me` dengan langkah reproduksi. Direspons secepatnya.

## Cakupan

- Klien ini **tidak menyimpan rahasia**. Ia bicara ke `skyward-api` dengan JWT
  yang dipegang pengguna.
- Kredensial API, secret webhook, dan konfigurasi server **tidak ada** di repo —
  hanya di server, mode 600 (lihat `deploy/env/*.example`).
- Token sesi disimpan di `localStorage` (klien statis; tidak ada cookie sesi
  server). XSS adalah risiko utama klien jenis ini, karena itu tidak ada
  `innerHTML` dari data server dan dependensi dijaga minimal.

## Praktik repo

- `gitleaks` dijalankan di CI (secret scanning).
- `.env` di-gitignore; hanya `.env.example` yang di-commit.
- Dependencies di-update via Dependabot.
