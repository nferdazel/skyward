#!/usr/bin/env bash
# Deploy skyward (monorepo: api/ Go + web/ SvelteKit) — pola cbs/fond/sds:
# build DI VPS, tanpa registry/GHCR, tanpa secrets GitHub.
#
#   - API : podman build -> ekstrak binary native -> restart + health gate + rollback
#   - Web : corepack pnpm install --frozen-lockfile && corepack pnpm run build -> swap folder statis (Caddy serve)
#
# Kontrak: ref-guard fail-closed, fetch+reset, hanya rebuild yang berubah,
# health-gated rollback untuk API, swap atomik + SELinux untuk web.
set -euo pipefail

REPO="${1:-skyward}"
REF="${2:-}"
LOG="/srv/qouver/apps/skyward/logs/deploy.log"
APP_DIR="/srv/qouver/apps/skyward"
mkdir -p "$APP_DIR/logs"
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

log "Deploy trigger received for: $REPO ref=$REF"

# Fail-closed: hanya deploy untuk push ke branch main
if [ -n "$REF" ] && [ "$REF" != "refs/heads/main" ]; then
  log "==> skip: ref=$REF (bukan main)"
  exit 0
fi

# URL clone repo (dari env VPS, mode 600). Contoh:
#   SKYWARD_GIT_URL=github-skyward:<user>/skyward.git
# Tidak di-hardcode supaya username tidak terekspos di repo publik.
if [ -z "${SKYWARD_GIT_URL:-}" ]; then
  log "==> ERROR: SKYWARD_GIT_URL tidak diset (mis. github-skyward:<user>/skyward.git)"
  exit 1
fi

MONO_DIR="$APP_DIR/monorepo"
STATE_FILE="$APP_DIR/.deployed_rev"
IS_FIRST=0

if [ -d "$MONO_DIR/.git" ]; then
  cd "$MONO_DIR"
  OLD_REV=$( [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "" )
  git fetch origin main && git reset --hard origin/main 2>&1 | tee -a "$LOG"
  NEW_REV=$(git rev-parse HEAD 2>/dev/null || echo "")
  if [ -n "$OLD_REV" ] && [ "$OLD_REV" != "$NEW_REV" ]; then
    # Hanya berkas yang bisa mengubah hasil build. Doc di dalam apps/ (mis.
    # apps/api/README.md) tidak boleh memicu rebuild + restart API yang tak perlu.
    CHANGED_FILES=$(git diff --name-only "$OLD_REV" "$NEW_REV" -- ':(exclude)*.md' 2>/dev/null || echo "apps/api/ apps/web/")
  else
    CHANGED_FILES="apps/api/ apps/web/"
  fi
else
  log "Cloning skyward -> $MONO_DIR"
  git clone "$SKYWARD_GIT_URL" "$MONO_DIR" 2>&1 | tee -a "$LOG"
  NEW_REV=$(git -C "$MONO_DIR" rev-parse HEAD 2>/dev/null || echo "")
  CHANGED_FILES="apps/api/ apps/web/"
  IS_FIRST=1
fi

# Self-update: samakan script server dengan versi repo (berlaku deploy berikutnya).
#
# Lewat file sementara + `mv` (rename), BUKAN `cp` langsung ke file yang sedang
# dijalankan: bash membaca script secara bertahap, jadi begitu isi file ditimpa
# di offset byte yang sama, sisa pembacaan jadi sampah — "syntax error near
# unexpected token" dan deploy mati sebelum mengerjakan apa pun. Terjadi
# 2026-10-12, tepat pada deploy pertama setelah script ini berubah. Rename
# membuat FD bash tetap menunjuk inode lama, sehingga aman.
REPO_SCRIPT="$MONO_DIR/deploy/deploy-vps.sh"
SELF_SCRIPT="$APP_DIR/scripts/deploy-vps.sh"
if [ -f "$REPO_SCRIPT" ] && ! cmp -s "$REPO_SCRIPT" "$SELF_SCRIPT"; then
  if cp -f "$REPO_SCRIPT" "$SELF_SCRIPT.new" && chmod +x "$SELF_SCRIPT.new"; then
    mv -f "$SELF_SCRIPT.new" "$SELF_SCRIPT" \
      && log "==> scripts/deploy-vps.sh diperbarui dari repo (berlaku deploy berikutnya)"
  else
    log "==> WARN: gagal menyiapkan $SELF_SCRIPT.new; script server dibiarkan apa adanya"
  fi
fi

# ── 0. Gate migrasi ──
# Repo TIDAK menerapkan DDL otomatis: host hanya punya podman (tanpa psql), dan
# migrate.sh butuh psql. Tapi bila ada file migrasi yang belum tercatat di
# schema_migrations, tolak deploy supaya kode baru tidak jalan di skema lama.
# Gate aktif saat 'migrations/' berubah ATAU di deploy pertama. Override darurat:
# SKIP_MIGRATION_GATE=1.
if [ "${SKIP_MIGRATION_GATE:-0}" = "1" ]; then
  log "==> WARN: SKIP_MIGRATION_GATE=1 — gate migrasi dilewati."
elif [ "$IS_FIRST" -eq 1 ] || grep -q "^migrations/" <<<"$CHANGED_FILES"; then
  log "==> Cek migrasi yang belum diterapkan..."
  if APPLIED=$(podman exec qouver-postgres psql -U qouver -d skyward -tAc \
       "select filename from schema_migrations" 2>&1); then
    if [ -z "$APPLIED" ]; then
      log "==> ERROR: schema_migrations kosong — semua migrasi belum tercatat."
      log "    Terapkan seluruh migrasi dulu, lalu deploy ulang."
      exit 1
    fi
    shopt -s nullglob
    PENDING=""
    for f in "$MONO_DIR"/migrations/*.sql; do
      b=$(basename "$f")
      grep -qxF "$b" <<<"$APPLIED" || PENDING="$PENDING $b"
    done
    shopt -u nullglob
    if [ -n "$PENDING" ]; then
      log "==> ERROR: migrasi belum diterapkan:$PENDING"
      log "    ($(grep -c . <<<"$APPLIED") migrasi tercatat di schema_migrations.)"
      log "    Terapkan dulu (mesin dev lewat tunnel + scripts/migrate.sh), lalu deploy ulang."
      exit 1
    fi
    log "==> Migrasi sinkron ($(grep -c . <<<"$APPLIED") tercatat)."

    # Verifikasi ISI migrasi yang sudah punya checksum di ledger. Migrasi bersifat
    # append-only: file yang isinya berubah (atau hilang) setelah diterapkan harus
    # memblokir deploy — dulu gate hanya membandingkan NAMA file, sehingga suntingan
    # pada migrasi lama lolos tanpa jejak.
    sha() {
      if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
      else
        shasum -a 256 "$1" | awk '{print $1}'
      fi
    }
    DRIFT=""
    while IFS='|' read -r name sum; do
      [ -z "$name" ] && continue
      [ -z "$sum" ] && continue
      if [ ! -f "$MONO_DIR/migrations/$name" ]; then
        DRIFT="$DRIFT $name(hilang)"
      elif [ "$(sha "$MONO_DIR/migrations/$name")" != "$sum" ]; then
        DRIFT="$DRIFT $name(berubah)"
      fi
    done < <(podman exec qouver-postgres psql -U qouver -d skyward -tAc \
             "select filename||'|'||checksum from schema_migrations where checksum is not null" 2>/dev/null)
    if [ -n "$DRIFT" ]; then
      log "==> ERROR: migrasi yang sudah diterapkan berubah isinya:$DRIFT"
      log "    Migrasi append-only: jangan edit/hapus yang sudah diterapkan; buat migrasi BARU."
      exit 1
    fi

    # Baris terlacak: sebutkan berapa migrasi lama yang tak bisa diverifikasi
    # (tercatat sebelum ledger menyimpan checksum). Bukti drift untuk mereka tidak
    # bisa direkonstruksi jujur — jadi hanya diinformasikan, bukan dipalsukan.
    NULLS=$(podman exec qouver-postgres psql -U qouver -d skyward -tAc \
            "select count(*) from schema_migrations where checksum is null" 2>/dev/null)
    if [ -n "$NULLS" ] && [ "$NULLS" != "0" ]; then
      log "    ($NULLS migrasi tercatat tanpa checksum — diterapkan sebelum ledger; isinya tak dapat diverifikasi.)"
    fi
  else
    log "==> WARN: tidak bisa membaca schema_migrations; gate dilewati. ($APPLIED)"
  fi
fi

# ── 1. API (Go, binary native) ──
if [ "$IS_FIRST" -eq 1 ] || grep -q "^apps/api/" <<<"$CHANGED_FILES"; then
  log "==> Build API (Go)..."
  cd "$MONO_DIR/apps/api"
  BIN_DIR="$APP_DIR/bin"
  BIN="$BIN_DIR/skyward-api"
  GIT_VERSION=$(git describe --tags --always 2>/dev/null || echo dev)
  GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo none)
  GIT_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  podman build --no-cache \
    --build-arg VERSION="$GIT_VERSION" \
    --build-arg COMMIT="$GIT_COMMIT" \
    --build-arg DATE="$GIT_DATE" \
    -t localhost/skyward-api:local . 2>&1 | tail -20 | tee -a "$LOG"
  mkdir -p "$BIN_DIR"
  # Simpan binary sebelumnya supaya rollout yang gagal bisa di-rollback.
  if [ -f "$BIN" ]; then cp -f "$BIN" "$BIN.prev"; fi
  CONTAINER_ID=$(podman create localhost/skyward-api:local)
  podman cp "$CONTAINER_ID:/usr/local/bin/skyward-api" "$BIN"
  podman rm "$CONTAINER_ID" >/dev/null

  systemctl --user daemon-reload 2>&1 | tee -a "$LOG" || true
  systemctl --user restart skyward-api 2>&1 | tee -a "$LOG"
  healthy=0
  for _ in $(seq 1 15); do
    if curl -fsS --max-time 3 http://127.0.0.1:8090/readyz >/dev/null 2>&1; then
      healthy=1; break
    fi
    sleep 2
  done
  if [ "$healthy" -ne 1 ]; then
    log "==> ERROR: /readyz tidak sehat setelah restart"
    if [ -f "$BIN.prev" ]; then
      log "==> rollback ke binary sebelumnya"
      cp -f "$BIN.prev" "$BIN"
      systemctl --user restart skyward-api 2>&1 | tee -a "$LOG"
      sleep 2
      systemctl --user is-active skyward-api 2>&1 | tee -a "$LOG" || true
    fi
    exit 1
  fi
  log "==> API sehat (/readyz OK)"
else
  log "==> api/ tidak berubah; melewati restart API (menghindari downtime tick)"
fi

# ── 2. Web (static) ──
if [ "$IS_FIRST" -eq 1 ] || grep -q "^apps/web/" <<<"$CHANGED_FILES"; then
  log "==> Build web (static)..."
  # Nilai build-time diambil dari env VPS (mode 600), bukan hardcode.
  # Utamakan env khusus web; fallback ke env prod lama yang memakai
  # SKYWARD_API_URL (kompatibel dengan setup Flutter sebelumnya).
  WEB_ENV="$APP_DIR/env/skyward-web.env"
  read_env() { grep -E "^$1=" "$2" 2>/dev/null | tail -1 | cut -d= -f2- || true; }
  VITE_SKYWARD_API_URL="$(read_env VITE_SKYWARD_API_URL "$WEB_ENV")"
  if [ -z "$VITE_SKYWARD_API_URL" ]; then
    VITE_SKYWARD_API_URL="$(read_env SKYWARD_API_URL "$APP_DIR/env/skyward-prod.env")"
  fi
  if [ -z "$VITE_SKYWARD_API_URL" ]; then
    log "==> ERROR: VITE_SKYWARD_API_URL/SKYWARD_API_URL tidak ditemukan di env — build web dibatalkan."
    exit 1
  fi
  cd "$MONO_DIR/apps/web"
  # pnpm (bukan npm) supaya dependensi yang dibangun = yang diuji CI
  # (pnpm-lock.yaml + --frozen-lockfile). Host hanya punya node+corepack
  # (pnpm tidak di PATH), jadi panggil lewat `corepack pnpm` — corepack mengambil
  # versi yang dipatok di package.json (packageManager), tanpa ubah PATH.
  export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
  corepack pnpm install --frozen-lockfile 2>&1 | tail -5 | tee -a "$LOG"
  VITE_SKYWARD_API_URL="$VITE_SKYWARD_API_URL" corepack pnpm run build 2>&1 | tail -10 | tee -a "$LOG"
  if [ -d "$MONO_DIR/apps/web/build" ]; then
    WEB_ROOT="$APP_DIR/web"
    WEB_NEW="$APP_DIR/web.new"
    rm -rf "$WEB_NEW"
    cp -a "$MONO_DIR/apps/web/build" "$WEB_NEW"
    rm -rf "$APP_DIR/web.prev"
    [ -d "$WEB_ROOT" ] && mv "$WEB_ROOT" "$APP_DIR/web.prev"
    mv "$WEB_NEW" "$WEB_ROOT"
    # SELinux: file baru berlabel var_t -> Caddy tidak bisa baca.
    restorecon -RF "$WEB_ROOT" 2>&1 | tail -2 | tee -a "$LOG" || true
    log "==> web swapped"
  else
    log "==> ERROR: build web tidak menghasilkan folder build/"
    exit 1
  fi
fi

log "Deployment completed successfully for $REPO"

if [ -n "${NEW_REV:-}" ]; then echo "$NEW_REV" > "$STATE_FILE"; fi
