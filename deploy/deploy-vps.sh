#!/usr/bin/env bash
# Deploy skyward (monorepo: api/ Go + web/ SvelteKit) — pola cbs/fond/sds:
# build DI VPS, tanpa registry/GHCR, tanpa secrets GitHub.
#
#   - API : podman build -> ekstrak binary native -> restart + health gate + rollback
#   - Web : npm run build -> swap folder statis (Caddy serve)
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

: "${SKYWARD_GIT_URL:=github-skyward:nferdazel/skyward.git}"

MONO_DIR="$APP_DIR/monorepo"
STATE_FILE="$APP_DIR/.deployed_rev"
IS_FIRST=0

if [ -d "$MONO_DIR/.git" ]; then
  cd "$MONO_DIR"
  OLD_REV=$( [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "" )
  git fetch origin main && git reset --hard origin/main 2>&1 | tee -a "$LOG"
  NEW_REV=$(git rev-parse HEAD 2>/dev/null || echo "")
  if [ -n "$OLD_REV" ] && [ "$OLD_REV" != "$NEW_REV" ]; then
    CHANGED_FILES=$(git diff --name-only "$OLD_REV" "$NEW_REV" 2>/dev/null || echo "apps/api/ apps/web/")
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
REPO_SCRIPT="$MONO_DIR/deploy/deploy-vps.sh"
SELF_SCRIPT="$APP_DIR/scripts/deploy-vps.sh"
if [ -f "$REPO_SCRIPT" ] && ! cmp -s "$REPO_SCRIPT" "$SELF_SCRIPT"; then
  cp -f "$REPO_SCRIPT" "$SELF_SCRIPT" && chmod +x "$SELF_SCRIPT" \
    && log "==> scripts/deploy-vps.sh diperbarui dari repo (berlaku deploy berikutnya)"
fi

# ── 1. API (Go, binary native) ──
if echo "$CHANGED_FILES" | grep -q "^apps/api/" || [ "$IS_FIRST" -eq 1 ]; then
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
if echo "$CHANGED_FILES" | grep -q "^apps/web/" || [ "$IS_FIRST" -eq 1 ]; then
  log "==> Build web (static)..."
  # Nilai build-time diambil dari env VPS (mode 600), bukan hardcode.
  WEB_ENV="$APP_DIR/env/skyward-web.env"
  VITE_SKYWARD_API_URL=$(grep -E '^VITE_SKYWARD_API_URL=' "$WEB_ENV" 2>/dev/null | tail -1 | cut -d= -f2- || true)
  if [ -z "$VITE_SKYWARD_API_URL" ]; then
    log "==> WARN: VITE_SKYWARD_API_URL tidak ada di $WEB_ENV; memakai default build."
  fi
  cd "$MONO_DIR/apps/web"
  npm install --no-audit --no-fund 2>&1 | tail -5 | tee -a "$LOG"
  VITE_SKYWARD_API_URL="$VITE_SKYWARD_API_URL" npm run build 2>&1 | tail -10 | tee -a "$LOG"
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
