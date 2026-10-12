# skyward-api

Backend Go yang otoritatif: REST API, push WebSocket, engine simulasi, dan
worker world-tick in-process. Satu binary (`cmd/server`), PostgreSQL via `pgx`.

## Menjalankan

Dari direktori `apps/api`:

```bash
cp ../.env.example .env   # isi DATABASE_URL, JWT_SECRET, dst.
go run ./cmd/server
```

Environment dibaca dari `.env` (lihat `.env.example` di root repo). Port default
`8090`.

## Test

```bash
go test ./...        # tanpa DB: test yang butuh DB di-skip
```

Test yang butuh DB (handler, store, engine) membaca `TEST_DATABASE_URL` dan
**wajib serial** — seluruh paket berbagi satu database, dan `WorldTick`
memproses pemain yang baru dibuat paket lain; paralel membuat tick memproses
user yang sudah dihapus (flake).

```bash
TEST_DATABASE_URL=postgres://…/skyward_test go test -p 1 ./...
```

## Struktur

| Paket | Isi |
|---|---|
| `cmd/server` | Entrypoint, wiring service, worker |
| `internal/engine` | Simulasi, ekonomi, armada, rute, bank, bot, world tick |
| `internal/handler` | HTTP handler (thin glue) |
| `internal/store` | Akses data (baca + tulis, termasuk normalisasi username) |
| `internal/realtime` | WebSocket hub (subscribe dibatasi allowlist channel) |
| `internal/middleware` | Auth, rate limit, trusted-proxy untuk IP klien |
| `internal/httperr` | Envelope error + pemetaan status HTTP |
| `internal/money` | Aturan uang & formula ekonomi bersama (pintu ledger) |
| `internal/worker` | Loop world-tick (pengganti pg_cron) + retensi |
| `internal/db` | Pool pgx + tracer query lambat |
| `internal/build` | Info versi binary (ldflags) |
| `internal/logfile` | Log harian `app-YYYY-MM-DD.log` + rotasi |
| `internal/config` | Konfigurasi env |

## Build

```bash
make build   # bin/skyward-api
make check   # vet + gofmt + test
```
