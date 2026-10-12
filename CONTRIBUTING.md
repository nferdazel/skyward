# Kontribusi

Repo satu orang, tapi standarnya tetap. Kode publik; jaga agar bersih dan
jujur.

## Alur

1. Buat branch dari `main`.
2. Commit kecil & fokus (micro-commit); pesan jelas.
3. Buka PR ke `main`. CI harus hijau.
4. Merge.

`main` dijaga sebagai **konvensi**: tidak ada push langsung untuk perubahan
berarti. Branch protection tidak diaktifkan di GitHub, jadi ini kesepakatan,
bukan penegakan otomatis.

## Aturan kode

- **Go**: `make check` (vet + gofmt + test). Test yang butuh DB — handler, store,
  engine — memakai `TEST_DATABASE_URL` dan **wajib serial**:
  `TEST_DATABASE_URL=… go test -p 1 ./...` (seluruh paket berbagi satu database).
- **Svelte/TypeScript**: `pnpm check`, `pnpm lint`, `pnpm test`, `pnpm build`
  harus hijau. TypeScript `strict`.
- **Test**: saat iterasi jalankan test yang terdampak saja; suite penuh sebelum
  push (CI menjalankan semuanya).
- **FE tidak menghitung ekonomi.** Semua angka otoritatif datang dari
  `skyward-api` (REST + WS). Lihat `ARCHITECTURE.md`.
- **Lapisan**: `ui/` tidak pernah memanggil `fetch`; lewat `state/` → `data/`.
- **Design system**: jangan improvisasi token warna/spacing — pakai
  `src/lib/core/theme/tokens.css`. Komponen generik boleh baru bila memang
  dipakai lintas fitur.
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
