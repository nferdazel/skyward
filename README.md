<div align="center">

# Skyward

**Web client untuk Skyward — airline tycoon simulation.**

SvelteKit · TypeScript · static · tanpa SSR

</div>

---

Skyward adalah simulasi manajemen maskapai: dirikan maskapai, beli atau sewa
pesawat, buka rute, pasang tarif, dan jaga neraca tetap hidup sementara sebuah
dunia bersama berjalan di bawahmu.

Repo ini adalah **klien web**. Seluruh logika ekonomi — demand, tarif, keausan,
kredit, arus kas — diputuskan oleh backend (Go, repo terpisah) yang bersifat
otoritatif. Klien merender apa yang dikatakan server dan mengirim perintah.
Jika server dan klien berbeda pendapat, server benar menurut definisi.

## Stack

- **SvelteKit** (`adapter-static`) + **TypeScript** strict
- **Svelte 5** runes untuk state
- **Vitest** + Testing Library untuk test
- Tanpa SSR, tanpa runtime Node di produksi — hasil build adalah file statis

## Struktur

```
web/       Klien SvelteKit (Svelte + TypeScript)
deploy/    Kontrak deploy (skrip webhook, Caddy contoh, env contoh)
```

`web/src/lib/core/` berisi infrastruktur lintas fitur (API client, realtime,
sync, tema, komponen). `web/src/lib/features/` berisi satu folder per fitur,
masing-masing dengan `data/` (gateway), `domain/` (tipe), `state/` (store), dan
`ui/` (komponen).

## Pengembangan lokal

Butuh Node 20+ dan pnpm.

```bash
cd web
pnpm install
pnpm dev        # dev server di http://localhost:5173
```

Dev server mengarah ke backend di `http://localhost:8090` (lihat
`.env.example`). Jalankan juga `skyward-api` secara lokal agar data muncul.

```bash
pnpm check      # svelte-check (tipe)
pnpm lint       # eslint + prettier
pnpm test       # vitest
pnpm build      # output statis di web/build/
```

## Build & deploy

- **CI** (`.github/workflows/ci.yml`): `check`, `lint`, `test`, `build` pada
  tiap push/PR, plus secret scan (gitleaks). Hanya verifikasi.
- **Deploy**: GitHub webhook → `deploy/deploy-vps.sh` di VPS. Build dilakukan
  **di VPS**, tanpa registry dan tanpa secret GitHub — pola yang sama dengan
  project Qouver lain. Detail: [`deploy/README.md`](deploy/README.md).

## Konfigurasi

Lihat [`.env.example`](.env.example). Nilai build-time:

| Variabel | Fungsi |
|---|---|
| `VITE_SKYWARD_API_URL` | Base URL `skyward-api` |

Nilai asli hanya ada di server. Tidak ada secret di repo ini.

## Lisensi

[MIT](LICENSE).
