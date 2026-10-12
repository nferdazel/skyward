<div align="center">

# Skyward

**Airline tycoon simulation — backend Go + web client SvelteKit.**

</div>

---

Skyward adalah simulasi manajemen maskapai: dirikan maskapai, beli atau sewa
pesawat, buka rute, pasang tarif, dan jaga neraca tetap hidup sementara sebuah
dunia bersama berjalan di bawahmu.

## Struktur monorepo

| Bagian | Stack | Fungsi |
|---|---|---|
| **`apps/api`** | Go + PostgreSQL (`pgx`) | Backend otoritatif: REST, WebSocket, engine simulasi, worker world-tick |
| **`apps/web`** | SvelteKit + TypeScript | Klien web statis (tanpa SSR) |
| `migrations/` | SQL | Migrasi skema (dijalankan `scripts/migrate.sh`) |
| `deploy/` | — | Kontrak deploy (webhook, Caddy contoh, env contoh) |
| `scripts/` | Bash | Operasi DB (migrate, prune, backup, drift-check) |

Server adalah **otoritatif** untuk seluruh ekonomi — demand, tarif, keausan,
kredit, arus kas. Klien merender apa yang dikatakan server dan mengirim
perintah. Jika server dan klien berbeda pendapat, server benar menurut definisi.

## Pengembangan lokal

Butuh Go 1.26+, Node 20+ (CI dan VPS memakai 24), pnpm, dan PostgreSQL.

```bash
# Backend
cp .env.example .env     # isi DATABASE_URL, JWT_SECRET, dst.
cd apps/api && go run ./cmd/server     # port 8090

# Frontend (terminal lain)
cd apps/web && pnpm install && pnpm dev  # http://localhost:5173
```

## Perintah

```bash
# API
cd apps/api
go build ./...
go test ./...            # tanpa DB: test yang butuh DB di-skip
make check               # vet + gofmt + test

# Web
cd apps/web
pnpm check               # svelte-check (tipe)
pnpm lint                # eslint + prettier
pnpm test                # vitest
pnpm build               # output statis di apps/web/build/
```

Test yang butuh DB (handler, store, engine) membaca `TEST_DATABASE_URL` dan
**wajib serial** — semua paket berbagi satu database:

```bash
TEST_DATABASE_URL=postgres://…/skyward_test go test -p 1 ./...
```

## Deploy

- **CI** (`.github/workflows/ci.yml`): build/vet/test Go + check/lint/test/build
  web + secret scan (gitleaks) pada tiap push/PR.
- **Deploy**: GitHub webhook → `deploy/deploy-vps.sh` di VPS. Build dilakukan
  **di VPS**, tanpa registry dan tanpa secret GitHub — pola yang sama dengan
  project Qouver lain. API memakai health gate + rollback; web di-swap atomik.
  Detail: [`deploy/README.md`](deploy/README.md).
- **Migrasi**: deploy tidak menerapkan DDL. Gate di skrip deploy menolak deploy
  bila ada migrasi yang belum tercatat di `schema_migrations`, atau bila isi
  berkas migrasi yang sudah diterapkan berubah (migrasi append-only).

## Konfigurasi

Lihat [`.env.example`](.env.example). Nilai asli hanya ada di server. Tidak ada
secret di repo ini.

## Lisensi

[MIT](LICENSE).
