# Kontrak deploy — skyward

Monorepo `apps/api` (Go) + `apps/web` (SvelteKit). Pola SAMA dengan project
Qouver lain (cbs-core, fond, sds, majadu): **build di VPS**, tanpa
registry/GHCR, tanpa secrets GitHub.

## Alur

```
push main
   └─► GitHub webhook (HMAC-SHA1) ──► webhook.service (VPS :9000)
          └─► deploy/deploy-vps.sh (di VPS)
                 ├─ apps/api  : podman build → ekstrak binary native →
                 │              restart skyward-api + health gate + rollback
                 └─ apps/web  : corepack pnpm install --frozen-lockfile
                                && corepack pnpm run build →
                                swap folder statis → /srv/qouver/apps/skyward/web
```

Hanya komponen yang berubah yang di-rebuild (dibandingkan dari `.deployed_rev`).

## Berkas di folder ini

| Berkas | Fungsi |
|---|---|
| `deploy-vps.sh` | Skrip deploy di VPS (di-trigger webhook) |
| `webhook.json` | Template hook untuk `webhook` (adnanh) — **secret tidak pernah di-commit**; konfigurasi asli ada di VPS |
| `Caddyfile.skyward.example` | Contoh blok Caddy untuk web statis |
| `env/*.example` | Contoh env |

## Setup di VPS (sekali)

1. Salin `deploy-vps.sh` → `/srv/qouver/apps/skyward/scripts/deploy-vps.sh`
   (chmod +x). Script self-update dari repo pada deploy berikutnya.
2. Clone key VPS → GitHub (deploy key), alias SSH `github-skyward`.
   Set `SKYWARD_GIT_URL` (mis. `github-skyward:<user>/skyward.git`) di env VPS
   (mode 600) — **tidak** di-hardcode di repo.
3. Tambahkan hook `skyward` ke `/srv/qouver/config/webhook.json`
   (gabung dari `deploy/webhook.json`, isi secret asli 64 karakter), lalu restart
   `webhook.service`. Catatan: layanan ini adalah systemd **user** unit
   (`systemctl --user restart webhook.service`), listen di `127.0.0.1:9000`, dan
   Caddy mem-proxy-nya ke publik lewat `handle /hooks/*` di `api.qouver.com` —
   jadi URL hook di GitHub adalah `https://api.qouver.com/hooks/skyward`.
   Cek cepat tanpa memicu deploy: `curl -s https://api.qouver.com/hooks/skyward`
   → `Hook rules were not satisfied.` (HMAC menolak).
4. Env web build-time: `/srv/qouver/apps/skyward/env/skyward-web.env` (mode 600)
   berisi `VITE_SKYWARD_API_URL=https://api.qouver.com/skyward`.
5. Pastikan fcontext SELinux `/srv/qouver/apps/skyward/web` =
   `httpd_sys_content_t` + `restorecon`.
6. Tambahkan blok Caddy (dari `Caddyfile.skyward.example`) lalu reload.

## Dependensi VPS

`podman`, `systemctl --user`, `curl`, `git` (+ deploy key), `node` (dengan
`corepack`, dipakai untuk pnpm), dan `restorecon` (SELinux). Build web memakai
`corepack pnpm --frozen-lockfile` (versi dipatok di `package.json`) agar identik
dengan CI. **psql/pg_dump tidak ada di host** — migrasi diterapkan dari mesin
dev, bukan oleh skrip deploy.

## Migrasi DB

Skrip deploy **tidak** menerapkan DDL. Sebagai gantinya ada gate: bila
`migrations/` ikut berubah dalam satu push tapi ada berkas yang belum tercatat di
`schema_migrations`, deploy **ditolak** (exit 1) sebelum API di-restart — supaya
kode baru tidak jalan di skema lama.

Gate juga memverifikasi **isi** migrasi yang sudah punya checksum di ledger: bila
berkas migrasi yang sudah diterapkan isinya berubah — atau berkasnya hilang —
deploy ditolak. Migrasi bersifat append-only, jadi perbaikan selalu dibuat sebagai
migrasi BARU. Baris ber-checksum NULL (diterapkan sebelum ledger menyimpan
checksum) hanya diinformasikan jumlahnya: isinya tak dapat diverifikasi jujur,
jadi tidak dipalsukan dengan checksum hari ini.

Menerapkan migrasi (butuh `psql`/`pg_dump`, jadi dari mesin dev lewat tunnel ke
DB VPS):

```bash
DATABASE_URL=postgres://qouver@127.0.0.1:15432/skyward scripts/migrate.sh
```

Setelah itu deploy ulang (atau push berikutnya) akan lolos gate. Override
darurat gate: `SKIP_MIGRATION_GATE=1` di env VPS.

Kalau sebuah migrasi sudah diterapkan manual tapi barisnya belum tercatat di
`schema_migrations`, `migrate.sh` akan mencoba menerapkannya ulang dan gagal
(`ON_ERROR_STOP`). Catat manual saja agar gate lolos:

```sql
-- checksum = sha256 berkas, atau NULL bila memang tak bisa diverifikasi
-- (diverifikasi oleh gate deploy dan migrate.sh hanya saat non-NULL)
INSERT INTO schema_migrations (filename, checksum)
VALUES ('NN_nama.sql', NULL)
ON CONFLICT (filename) DO NOTHING;
```

## Health gate & rollback

- API dianggap sehat bila `GET /readyz` (127.0.0.1:8090) merespons dalam 30s.
  Gagal → binary `.prev` dipulihkan dan service di-restart.
- Web di-swap atomik (`web.new` → `web`, lama → `web.prev`).
