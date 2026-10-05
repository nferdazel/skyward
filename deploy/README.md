# Kontrak deploy — skyward web

Pola SAMA dengan project Qouver lain (cbs-core, fond, sds, majadu):
**build di VPS**, tanpa registry/GHCR, tanpa secrets GitHub.

## Alur

```
push main
   └─► GitHub webhook (HMAC-SHA1) ──► webhook.service (VPS :9000)
          └─► deploy/deploy-vps.sh (di VPS)
                 ├─ git fetch + reset (clone bila pertama)
                 ├─ cd web && npm install && npm run build
                 └─ swap folder statis → /srv/qouver/apps/skyward/web
```

## Berkas di folder ini

| Berkas | Fungsi |
|---|---|
| `deploy-vps.sh` | Skrip deploy di VPS (di-trigger webhook) |
| `webhook.json` | Konfigurasi hook untuk `webhook.service` (placeholder secret) |
| `Caddyfile.skyward.example` | Contoh blok Caddy |
| `env/*.example` | Contoh env (bila perlu) |

## Setup di VPS (sekali)

1. Salin `deploy-vps.sh` → `/srv/qouver/apps/skyward/scripts/deploy-vps.sh`
   (chmod +x). Script self-update dari repo pada deploy berikutnya.
2. Clone key VPS → GitHub (deploy key) dengan alias SSH `github-skyward`.
   Diperlukan karena repo privat; `SKYWARD_GIT_URL` mengarah ke alias ini.
3. Tambahkan hook `skyward-web` ke `/srv/qouver/config/webhook.json`
   (gabung dari `deploy/webhook.json`, isi secret asli), lalu restart
   `webhook.service`.
4. Pastikan fcontext SELinux `/srv/qouver/apps/skyward/web` =
   `httpd_sys_content_t` + `restorecon`.
5. Tambahkan blok Caddy (dari `Caddyfile.skyward.example`) lalu reload.
