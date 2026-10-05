#!/usr/bin/env bash
# Prune tabel yang tumbuh tanpa batas, lalu VACUUM (bukan FULL).
#
# LATAR: fungsi `prune_bank_transactions` dan `prune_world_tick_log` ada di
# `migrations/00_baseline.sql` (era pg_cron) tetapi TIDAK dipanggil siapa pun
# sejak world tick pindah ke worker Go in-process. `pg_cron` juga tidak
# terpasang (lihat `migrations/18_retire_pgcron_scheduler_health.sql`), jadi
# `bank_transactions` dan `world_tick_log` hanya tumbuh. Skrip ini yang
# menjalankan prune-nya, di luar jalur tick.
#
# Usage (VPS, podman):
#   PSQL='podman exec -i qouver-postgres psql -U qouver -d skyward' scripts/prune-db.sh
# Usage (local):
#   DATABASE_URL=postgres://... scripts/prune-db.sh
#
# Default DRY-RUN. Untuk benar-benar menghapus: APPLY=1 scripts/prune-db.sh
set -euo pipefail

if [ -n "${PSQL:-}" ]; then
  # shellcheck disable=SC2206
  PSQL_CMD=($PSQL)
else
  : "${DATABASE_URL:?set DATABASE_URL, atau PSQL untuk psql kustom}"
  PSQL_CMD=(psql "$DATABASE_URL")
fi

q()    { "${PSQL_CMD[@]}" -q -tA -v ON_ERROR_STOP=1 -c "$1"; }
run()  { "${PSQL_CMD[@]}" -v ON_ERROR_STOP=1 "$@"; }
apply=${APPLY:-0}

echo "==> ukuran tabel sebelum"
run -c "SELECT c.relname, pg_size_pretty(pg_total_relation_size(c.oid)) AS total,
               COALESCE(s.n_live_tup,0) AS live_rows
        FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
        LEFT JOIN pg_stat_user_tables s ON s.relid=c.oid
        WHERE n.nspname='public' AND c.relkind='r'
          AND c.relname IN ('bank_transactions','world_tick_log','finance_snapshots')
        ORDER BY pg_total_relation_size(c.oid) DESC;"

# 1. Hitung kandidat (dry-run) — retention dari game_config, fallback sama
#    dengan yang dipakai fungsi baseline.
cutoff_count=$(q "
  WITH cfg AS (
    SELECT COALESCE(get_config_int('bank_txn_raw_retention_game_days'), 180) AS days
  ), sc AS (
    SELECT current_game_time FROM season_clock WHERE status='active' ORDER BY created_at ASC LIMIT 1
  )
  SELECT count(*) FROM bank_transactions bt, cfg, sc
  WHERE bt.game_date IS NOT NULL
    AND bt.game_date < sc.current_game_time - (cfg.days || ' days')::interval
    AND bt.game_date > '1970-01-01'::timestamptz;")
echo "==> bank_transactions: $cutoff_count baris di luar horizon akan dihapus"

if [ "$apply" != "1" ]; then
  echo "==> DRY-RUN (set APPLY=1 untuk eksekusi). Tidak ada yang diubah."
  exit 0
fi

# 2. Hapus bank_transactions dalam batch untuk menghindari lock/WAL besar.
batch=${BATCH_SIZE:-100000}
total=0
while :; do
  deleted=$(q "
    WITH cfg AS (
      SELECT COALESCE(get_config_int('bank_txn_raw_retention_game_days'), 180) AS days
    ), sc AS (
      SELECT current_game_time FROM season_clock WHERE status='active' ORDER BY created_at ASC LIMIT 1
    ), victims AS (
      SELECT bt.id FROM bank_transactions bt, cfg, sc
      WHERE bt.game_date IS NOT NULL
        AND bt.game_date < sc.current_game_time - (cfg.days || ' days')::interval
        AND bt.game_date > '1970-01-01'::timestamptz
      LIMIT $batch
    ), del AS (
      DELETE FROM bank_transactions WHERE id IN (SELECT id FROM victims) RETURNING 1
    )
    SELECT count(*) FROM del;")
  [ "$deleted" = "0" ] && break
  total=$((total + deleted))
  echo "    dihapus $deleted ($total total)"
  sleep 1
done
echo "==> bank_transactions: $total baris dihapus"

# 3. world_tick_log — retensi hari REAL, bukan game time.
tick_deleted=$(q "
  WITH cfg AS (
    SELECT COALESCE(get_config_int('world_tick_log_raw_real_days'), 7) AS days
  ), del AS (
    DELETE FROM world_tick_log
    WHERE started_at < NOW() - (SELECT days FROM cfg) * interval '1 day'
    RETURNING 1
  ) SELECT count(*) FROM del;")
echo "==> world_tick_log: $tick_deleted baris dihapus"

# 4. VACUUM (ANALYZE) — bukan FULL: tidak butuh ruang disk 2x dan tidak mengunci
#    tabel secara eksklusif. Jalankan FULL manual bila ingin ruang kembali penuh.
echo "==> VACUUM (ANALYZE)"
run -c "VACUUM (ANALYZE) bank_transactions; VACUUM (ANALYZE) world_tick_log;"

echo "==> ukuran tabel sesudah"
run -c "SELECT c.relname, pg_size_pretty(pg_total_relation_size(c.oid)) AS total,
               COALESCE(s.n_live_tup,0) AS live_rows
        FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
        LEFT JOIN pg_stat_user_tables s ON s.relid=c.oid
        WHERE n.nspname='public' AND c.relkind='r'
          AND c.relname IN ('bank_transactions','world_tick_log','finance_snapshots')
        ORDER BY pg_total_relation_size(c.oid) DESC;"

echo "==> selesai"
