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
                 └─ apps/web  : npm install && npm run build →
                                swap folder statis → /srv/qouver/apps/skyward/web
```

Hanya komponen yang berubah yang di-rebuild (dibandingkan dari `.deployed_rev`).

## Berkas di folder ini

| Berkas | Fungsi |
|---|---|
| `deploy-vps.sh` | Skrip deploy di VPS (di-trigger webhook) |
| `webhook.json` | Konfigurasi hook untuk `webhook.service` (placeholder secret) |
| `Caddyfile.skyward.example` | Contoh blok Caddy untuk web statis |
| `env/*.example` | Contoh env |

## Setup di VPS (sekali)

1. Salin `deploy-vps.sh` → `/srv/qouver/apps/skyward/scripts/deploy-vps.sh`
   (chmod +x). Script self-update dari repo pada deploy berikutnya.
2. Clone key VPS → GitHub (deploy key), alias SSH `github-skyward`
   (`SKYWARD_GIT_URL` mengarah ke alias ini).
3. Tambahkan hook `skyward` ke `/srv/qouver/config/webhook.json`
   (gabung dari `deploy/webhook.json`, isi secret asli), lalu restart
   `webhook.service`.
4. Env web build-time: `/srv/qouver/apps/skyward/env/skyward-web.env` (mode 600)
   berisi `VITE_SKYWARD_API_URL=https://api.qouver.com/skyward`.
5. Pastikan fcontext SELinux `/srv/qouver/apps/skyward/web` =
   `httpd_sys_content_t` + `restorecon`.
6. Tambahkan blok Caddy (dari `Caddyfile.skyward.example`) lalu reload.

## Health gate & rollback

- API dianggap sehat bila `GET /readyz` (127.0.0.1:8090) merespons dalam 30s.
  Gagal → binary `.prev` dipulihkan dan service di-restart.
- Web di-swap atomik (`web.new` → `web`, lama → `web.prev`).
