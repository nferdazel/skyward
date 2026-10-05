# Kontribusi

Repo satu orang, tapi standarnya tetap. Kode publik; jaga agar bersih dan
jujur.

## Alur

1. Buat branch dari `main`.
2. Commit kecil & fokus (micro-commit); pesan jelas.
3. Buka PR ke `main`. CI harus hijau.
4. Merge.

`main` dijaga: tidak ada push langsung untuk perubahan berarti.

## Aturan kode

- **Svelte/TypeScript**: `pnpm check`, `pnpm lint`, `pnpm test`, `pnpm build`
  harus hijau. TypeScript `strict`.
- **FE tidak menghitung ekonomi.** Semua angka otoritatif datang dari
  `skyward-api` (REST + WS). Lihat `ARCHITECTURE.md`.
- **Lapisan**: `ui/` tidak pernah memanggil `fetch`; lewat `state/` → `data/`.
- **Jangan commit** secret, `.env` asli, atau artefak build (`build/`,
  `.svelte-kit/`).
- **Jangan commit** isi `docs/` (dokumen internal, memang di-gitignore).

## Commit

Pesan dalam bahasa Indonesia atau Inggris, konsisten. Contoh:

```
feat(fleet): tambah tabel armada dan drawer detail
fix(api-client): parse envelope error Go dengan benar
docs(readme): perjelas alur build & deploy
```
