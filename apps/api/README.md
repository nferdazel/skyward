# skyward-api

Authoritative Go backend: REST API, WebSocket push, simulation engine, and the
in-process world-tick worker. Single binary (`cmd/server`), PostgreSQL via `pgx`.

## Menjalankan

Dari direktori `api/`:

```bash
cp ../.env.example .env   # isi DATABASE_URL, JWT_SECRET, dst.
go run ./cmd/server
```

Environment dibaca dari `.env` (lihat `.env.example` di root repo). Port default
`8090`.

## Test

```bash
go test ./...
```

Logika domain (`internal/engine`) teruji. Test DB (`store`, `config`, `db`)
belum — lihat `docs/ARCHITECTURE.md` §3 (B1) untuk rencana harness.

## Struktur

| Paket | Isi |
|---|---|
| `cmd/server` | Entrypoint, wiring service, worker |
| `internal/engine` | Simulasi, ekonomi, armada, rute, bank, bot, world tick |
| `internal/handler` | HTTP handler (thin glue) |
| `internal/store` | Query baca |
| `internal/realtime` | WebSocket hub |
| `internal/middleware` | Auth, rate limit |
| `internal/config` | Konfigurasi env |

## Build

```bash
make build   # bin/skyward-api
make check   # vet + gofmt + test
```
