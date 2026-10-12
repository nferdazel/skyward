-- 26_world_tick_log_degraded.sql — izinkan status 'degraded' di world_tick_log
--
-- LATAR: port Go (`engine.writeTickLog`, AUDIT-06) mencatat SATU baris per tick
-- dengan status 'degraded' bila ada player/bot yang gagal. Constraint lama
-- (warisan baseline SQL, yang mencatat kegagalan sebagai baris `player_error`/
-- `bot_error` terpisah) hanya mengizinkan
-- started/skipped/success/error/player_error/bot_error.
--
-- Akibatnya INSERT status 'degraded' melanggar CHECK, gagal, dan error-nya
-- hanya masuk log aplikasi — sehingga tick yang terdegradasi TIDAK PERNAH
-- tercatat. Di prod hanya ada baris 'success' (kegagalan tak terlihat).
--
-- Ini perubahan aditif (melonggarkan CHECK, bukan memperketat): aman & reversibel.
-- Idempoten. Apply: podman exec -i qouver-postgres psql -U qouver -d skyward -v ON_ERROR_STOP=1 < this.sql

BEGIN;

ALTER TABLE public.world_tick_log
    DROP CONSTRAINT IF EXISTS world_tick_log_status_check;

ALTER TABLE public.world_tick_log
    ADD CONSTRAINT world_tick_log_status_check
    CHECK (status::text = ANY (ARRAY[
        'started', 'skipped', 'success', 'error', 'player_error', 'bot_error', 'degraded'
    ]::text[]));

COMMIT;
