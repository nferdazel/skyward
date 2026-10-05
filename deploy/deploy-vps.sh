#!/usr/bin/env bash
# Deploy skyward web — pola SAMA dengan fond/cbs/sds/majadu: build DI VPS.
# Tanpa registry, tanpa GHCR, tanpa secrets GitHub.
#
#   - Web : npm run build -> folder statis (Caddy serve)
#
# Kontrak tetap: ref-guard fail-closed, fetch+reset, swap folder atomik, SELinux.
set -euo pipefail

REPO="${1:-skyward-web}"
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

: "${SKYWARD_GIT_URL:=github-skyward:nferdazel/skyward-web.git}"

REPO_DIR="$APP_DIR/web-src"
STATE_FILE="$APP_DIR/.deployed_rev"
IS_FIRST=0

if [ -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR"
  OLD_REV=$( [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo "" )
  git fetch origin main && git reset --hard origin/main 2>&1 | tee -a "$LOG"
else
  log "Cloning skyward-web -> $REPO_DIR"
  git clone "$SKYWARD_GIT_URL" "$REPO_DIR" 2>&1 | tee -a "$LOG"
  IS_FIRST=1
fi

# Self-update: samakan script server dengan versi di repo agar tidak drift.
REPO_SCRIPT="$REPO_DIR/deploy/deploy-vps.sh"
SELF_SCRIPT="$APP_DIR/scripts/deploy-vps.sh"
if [ -f "$REPO_SCRIPT" ] && ! cmp -s "$REPO_SCRIPT" "$SELF_SCRIPT"; then
  cp -f "$REPO_SCRIPT" "$SELF_SCRIPT" && chmod +x "$SELF_SCRIPT" \
    && log "==> scripts/deploy-vps.sh diperbarui dari repo (berlaku deploy berikutnya)"
fi

log "==> Build web (static)..."
cd "$REPO_DIR/web"
npm install --no-audit --no-fund 2>&1 | tail -5 | tee -a "$LOG"
npm run build 2>&1 | tail -10 | tee -a "$LOG"

if [ -d "$REPO_DIR/web/build" ]; then
  WEB_NEW="$APP_DIR/web.new"
  rm -rf "$WEB_NEW"
  cp -a "$REPO_DIR/web/build" "$WEB_NEW"
  rm -rf "$APP_DIR/web.prev"
  [ -d "$APP_DIR/web" ] && mv "$APP_DIR/web" "$APP_DIR/web.prev"
  mv "$WEB_NEW" "$APP_DIR/web"
  # SELinux: file baru berlabel var_t -> Caddy tidak bisa baca. Terapkan
  # httpd_sys_content_t (fcontext sudah didefinisikan di server).
  restorecon -RF "$APP_DIR/web/" 2>&1 | tail -2 | tee -a "$LOG" || true
  log "==> web swapped"
else
  log "==> ERROR: build web tidak menghasilkan folder build/"
  exit 1
fi

log "Deployment completed successfully for $REPO"

NEW_REV=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo "")
if [ -n "$NEW_REV" ]; then
  echo "$NEW_REV" > "$STATE_FILE"
fi
