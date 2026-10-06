package worker

import (
	"context"
	"os"
	"testing"

	"github.com/jackc/pgx/v5/pgxpool"
)

// TestReadTickIntervalSecondsDB membuktikan worker membaca
// `season_clock.tick_interval_seconds` dari season aktif (menutup TODO: ticker
// mengikuti perubahan interval admin). Butuh TEST_DATABASE_URL; di-skip bila
// tidak diset.
func TestReadTickIntervalSecondsDB(t *testing.T) {
	dbURL := os.Getenv("TEST_DATABASE_URL")
	if dbURL == "" {
		t.Skip("TEST_DATABASE_URL tidak diset")
	}
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()

	// Pakai season aktif yang ada (baseline migrasi). Update interval-nya lalu
	// pastikan worker membacanya, lalu pulihkan.
	var id string
	var original int
	if err := pool.QueryRow(ctx,
		`SELECT id, tick_interval_seconds FROM season_clock WHERE status='active' LIMIT 1`).
		Scan(&id, &original); err != nil {
		t.Fatalf("butuh season aktif pada baseline: %v", err)
	}
	t.Cleanup(func() {
		_, _ = pool.Exec(context.Background(),
			`UPDATE season_clock SET tick_interval_seconds=$1 WHERE id=$2`, original, id)
	})

	if _, err := pool.Exec(ctx,
		`UPDATE season_clock SET tick_interval_seconds=42 WHERE id=$1`, id); err != nil {
		t.Fatalf("update interval: %v", err)
	}

	secs, ok := (&Worker{pool: pool}).readTickIntervalSeconds(ctx)
	if !ok {
		t.Fatal("harusnya menemukan season aktif")
	}
	if secs != 42 {
		t.Fatalf("expected 42, got %d", secs)
	}
}
