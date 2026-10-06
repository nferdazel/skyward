package engine

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"skyward-api/internal/store"
)

// TestDailyMaintenanceRetentionDB membuktikan retensi `runDailyMaintenance`
// (B6) berjalan tepat pada batas GAME DAY dan memakai horizon dari game_config:
//
//  1. baris bank_transactions DI LUAR horizon (>180 hari game) dihapus;
//  2. baris DI DALAM horizon tetap;
//  3. saat `gameTimeBefore` dan `gameTimeAfter` berada di hari game yang sama,
//     retensi TIDAK berjalan (baris lama dibiarkan) — inilah yang membuktikan
//     ia hanya jalan sekali per game day, bukan tiap tick.
//
// Butuh `TEST_DATABASE_URL` (database hasil migrasi); di-skip bila tidak diset.
func TestDailyMaintenanceRetentionDB(t *testing.T) {
	dbURL := os.Getenv("TEST_DATABASE_URL")
	if dbURL == "" {
		t.Skip("TEST_DATABASE_URL tidak diset; test ini butuh database hasil `make migrate`")
	}
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()

	st := store.New(pool)
	eng := New(pool, st)

	// User + akun operasional (FK bank_transactions.account_id & user_id).
	const uname = "b6_retention_probe"
	_, _ = pool.Exec(ctx, `DELETE FROM users WHERE username=$1`, uname)
	var uid, acctID string
	if err := pool.QueryRow(ctx, `
		INSERT INTO users (username, password_hash, company_name, ceo_name,
		                   hq_airport_iata, game_current_time, actor_type, onboarding_completed)
		VALUES ($1, 'x', 'B6 Air', 'Probe', 'SIN', now(), 'REAL', true)
		RETURNING id`, uname).Scan(&uid); err != nil {
		t.Fatalf("insert user: %v", err)
	}
	t.Cleanup(func() { _, _ = pool.Exec(ctx, `DELETE FROM users WHERE username=$1`, uname) })

	if err := pool.QueryRow(ctx, `
		INSERT INTO bank_accounts (user_id, account_type, balance)
		VALUES ($1, 'operating', 0)
		ON CONFLICT (user_id, account_type) DO UPDATE SET balance = 0
		RETURNING id`, uid).Scan(&acctID); err != nil {
		t.Fatalf("insert account: %v", err)
	}
	// Bersihkan sisa baris dari eksekusi sebelumnya (idempoten).
	if _, err := pool.Exec(ctx, `DELETE FROM bank_transactions WHERE user_id=$1`, uid); err != nil {
		t.Fatalf("bersihkan txn lama: %v", err)
	}

	// gameTimeAfter jauh di masa depan game; horizon retensi = 180 hari game.
	gameTimeAfter := time.Now().UTC().Add(2000 * 24 * time.Hour)
	gameTimeBefore := gameTimeAfter.Add(-1 * time.Hour) // hari yang sama dengan after
	insertTxn := func(daysAgo float64) string {
		var id string
		gameDate := gameTimeAfter.Add(-time.Duration(daysAgo * 24 * float64(time.Hour)))
		if err := pool.QueryRow(ctx, `
			INSERT INTO bank_transactions (account_id, user_id, transaction_type, amount, balance_after, game_date)
			VALUES ($1, $2, 'debit', 100, 0, $3) RETURNING id`, acctID, uid, gameDate).Scan(&id); err != nil {
			t.Fatalf("insert txn: %v", err)
		}
		return id
	}

	// 1. Hari yang SAMA sebelum/sesudah => retensi tidak jalan.
	sameDayOld := insertTxn(400) // di luar horizon, tapi belum saatnya
	eng.runDailyMaintenance(ctx, "", gameTimeBefore, gameTimeAfter)
	if !rowExists(t, ctx, pool, sameDayOld) {
		t.Fatal("retensi berjalan padahal gameTimeBefore/After masih hari game yang sama")
	}

	// 2. Lintasi batas hari game => retensi jalan.
	oldID := insertTxn(400) // di luar 180 hari game
	freshID := insertTxn(10) // di dalam horizon
	crossDayBefore := gameTimeAfter.Add(-24 * time.Hour)
	eng.runDailyMaintenance(ctx, "", crossDayBefore, gameTimeAfter)

	if rowExists(t, ctx, pool, oldID) {
		t.Error("baris di luar horizon (400 hari game) seharusnya dihapus")
	}
	if !rowExists(t, ctx, pool, freshID) {
		t.Error("baris di dalam horizon (10 hari game) tidak boleh dihapus")
	}
	// Baris hari-sama dari langkah 1 juga harus ikut terhapus sekarang.
	if rowExists(t, ctx, pool, sameDayOld) {
		t.Error("baris di luar horizon dari langkah 1 seharusnya dihapus saat lintas hari")
	}
}

func rowExists(t *testing.T, ctx context.Context, pool *pgxpool.Pool, id string) bool {
	t.Helper()
	var exists bool
	if err := pool.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM bank_transactions WHERE id=$1)`, id).Scan(&exists); err != nil {
		t.Fatalf("cek baris: %v", err)
	}
	return exists
}
