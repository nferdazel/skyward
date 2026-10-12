package engine

import (
	"context"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"skyward-api/internal/store"
)

// DB-gated: butuh `TEST_DATABASE_URL` (database hasil migrasi); di-skip bila tidak
// diset, sama seperti test DB lain di paket ini.

// testEngine — pool + engine siap pakai untuk test DB, plus helper pembersihan.
func testEngine(t *testing.T) (context.Context, *pgxpool.Pool, *Engine) {
	t.Helper()
	dbURL := os.Getenv("TEST_DATABASE_URL")
	if dbURL == "" {
		t.Skip("TEST_DATABASE_URL tidak diset; test ini butuh database hasil `make migrate`")
	}
	ctx := context.Background()
	pool, err := pgxpool.New(ctx, dbURL)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	return ctx, pool, New(pool, store.New(pool))
}

// testPlayer — user + akun operasional dengan saldo tertentu. Idempoten (dibersihkan).
func testPlayer(t *testing.T, ctx context.Context, pool *pgxpool.Pool, uname string, cash float64) string {
	t.Helper()
	_, _ = pool.Exec(ctx, `DELETE FROM users WHERE username=$1`, uname)
	var uid string
	// company_name punya UNIQUE constraint → harus unik per user probe; kalau tidak,
	// user sisa run yang mati di tengah membuat insert berikutnya bentrok.
	company := "Probe " + uname
	if err := pool.QueryRow(ctx, `
		INSERT INTO users (username, password_hash, company_name, ceo_name,
		                   hq_airport_iata, game_current_time, actor_type, onboarding_completed)
		VALUES ($1, 'x', $2, 'Probe', 'SIN', now(), 'REAL', true)
		RETURNING id`, uname, company).Scan(&uid); err != nil {
		t.Fatalf("insert user: %v", err)
	}
	t.Cleanup(func() { _, _ = pool.Exec(ctx, `DELETE FROM users WHERE username=$1`, uname) })
	if _, err := pool.Exec(ctx, `
		INSERT INTO bank_accounts (user_id, account_type, balance)
		VALUES ($1, 'operating', $2)
		ON CONFLICT (user_id, account_type) DO UPDATE SET balance = EXCLUDED.balance`,
		uid, cash); err != nil {
		t.Fatalf("insert account: %v", err)
	}
	return uid
}

// testAircraft — satu pesawat untuk user, memakai model dari reference data.
func testAircraft(t *testing.T, ctx context.Context, pool *pgxpool.Pool, uid, tail string) string {
	t.Helper()
	var modelID string
	if err := pool.QueryRow(ctx, `SELECT id FROM aircraft_models LIMIT 1`).Scan(&modelID); err != nil {
		t.Fatalf("tidak ada aircraft_models (reference data belum di-seed?): %v", err)
	}
	var id string
	if err := pool.QueryRow(ctx, `
		INSERT INTO fleet_aircraft (user_id, aircraft_model_id, acquisition_type, tail_number, status)
		VALUES ($1, $2, 'purchase', $3, 'active') RETURNING id`, uid, modelID, tail).Scan(&id); err != nil {
		t.Fatalf("insert aircraft: %v", err)
	}
	return id
}

// TestApplyBankruptcyAtomicallyComplete — satu panggilan harus menuntaskan
// SEMUA efek: status Bankrupt, armada grounded, pinjaman default+balance 0,
// rute aktif dibatalkan. Dulu empat Exec terpisah dengan error dibuang, jadi
// pemain bisa setengah-bangkrut.
func TestApplyBankruptcyAtomicallyComplete(t *testing.T) {
	ctx, pool, eng := testEngine(t)
	uid := testPlayer(t, ctx, pool, "d2_bankruptcy_probe", 5000)
	aircraftID := testAircraft(t, ctx, pool, uid, "D2Z001")

	if _, err := pool.Exec(ctx, `
		INSERT INTO loans (user_id, principal, remaining_balance, weekly_payment, status, loan_type, collateral_aircraft_id)
		VALUES ($1, 100000, 50000, 1000, 'active', 'unsecured', $2)`, uid, aircraftID); err != nil {
		t.Fatalf("insert loan: %v", err)
	}
	if _, err := pool.Exec(ctx, `
		INSERT INTO route_assignments (user_id, origin_iata, destination_iata, distance_km, ticket_price, status)
		VALUES ($1, 'SIN', 'KUL', 300, 120, 'active')`, uid); err != nil {
		t.Fatalf("insert route: %v", err)
	}

	eng.applyBankruptcy(ctx, uid)

	var status string
	if err := pool.QueryRow(ctx, `SELECT operational_status FROM users WHERE id=$1`, uid).Scan(&status); err != nil {
		t.Fatal(err)
	}
	if status != "Bankrupt" {
		t.Errorf("operational_status = %q, mau Bankrupt", status)
	}

	var fleetGrounded int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM fleet_aircraft WHERE user_id=$1 AND status='grounded'`, uid).Scan(&fleetGrounded); err != nil {
		t.Fatal(err)
	}
	if fleetGrounded != 1 {
		t.Errorf("armada grounded = %d, mau 1", fleetGrounded)
	}

	var loanStatus string
	var loanBalance float64
	if err := pool.QueryRow(ctx, `SELECT status, remaining_balance FROM loans WHERE user_id=$1`, uid).Scan(&loanStatus, &loanBalance); err != nil {
		t.Fatal(err)
	}
	if loanStatus != "defaulted" || loanBalance != 0 {
		t.Errorf("loan = (%q, %.2f), mau (defaulted, 0)", loanStatus, loanBalance)
	}

	var routeCancelled int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM route_assignments WHERE user_id=$1 AND status='cancelled'`, uid).Scan(&routeCancelled); err != nil {
		t.Fatal(err)
	}
	if routeCancelled != 1 {
		t.Errorf("rute dibatalkan = %d, mau 1", routeCancelled)
	}
}

// TestProcessLoanPaymentsDebitsWhenCashAvailable — saldo cukup: saldo turun dan
// sisa pinjaman turun sebesar angsuran, tanpa missed_payments.
func TestProcessLoanPaymentsDebitsWhenCashAvailable(t *testing.T) {
	ctx, pool, eng := testEngine(t)
	uid := testPlayer(t, ctx, pool, "d2_loan_pay_probe", 10000)

	if _, err := pool.Exec(ctx, `
		INSERT INTO loans (user_id, principal, remaining_balance, weekly_payment, status, loan_type)
		VALUES ($1, 100000, 50000, 2000, 'active', 'unsecured')`, uid); err != nil {
		t.Fatalf("insert loan: %v", err)
	}

	eng.ProcessLoanPayments(ctx, uid, time.Now().UTC())

	var balance, remaining float64
	var missed int
	if err := pool.QueryRow(ctx, `SELECT COALESCE(balance,0) FROM bank_accounts WHERE user_id=$1 AND account_type='operating'`, uid).Scan(&balance); err != nil {
		t.Fatal(err)
	}
	if err := pool.QueryRow(ctx, `SELECT remaining_balance, missed_payments FROM loans WHERE user_id=$1`, uid).Scan(&remaining, &missed); err != nil {
		t.Fatal(err)
	}
	if balance != 8000 {
		t.Errorf("saldo = %.2f, mau 8000", balance)
	}
	if remaining != 48000 {
		t.Errorf("sisa pinjaman = %.2f, mau 48000", remaining)
	}
	if missed != 0 {
		t.Errorf("missed_payments = %d, mau 0", missed)
	}
}

// TestProcessLoanPaymentsDefaultsAfterFourMisses — saldo nol: tiap hari denda
// 10% + missed_payments naik; pada missed ke-4 pinjaman default dan jaminan
// di-groundkan.
func TestProcessLoanPaymentsDefaultsAfterFourMisses(t *testing.T) {
	ctx, pool, eng := testEngine(t)
	uid := testPlayer(t, ctx, pool, "d2_loan_default_probe", 0)
	aircraftID := testAircraft(t, ctx, pool, uid, "D2Z002")

	if _, err := pool.Exec(ctx, `
		INSERT INTO loans (user_id, principal, remaining_balance, weekly_payment, status, loan_type, collateral_aircraft_id)
		VALUES ($1, 100000, 50000, 1000, 'active', 'unsecured', $2)`, uid, aircraftID); err != nil {
		t.Fatalf("insert loan: %v", err)
	}

	gameDate := time.Now().UTC()
	for i := 0; i < 4; i++ {
		eng.ProcessLoanPayments(ctx, uid, gameDate)
	}

	var status string
	var remaining float64
	var missed int
	if err := pool.QueryRow(ctx, `SELECT status, remaining_balance, missed_payments FROM loans WHERE user_id=$1`, uid).Scan(&status, &remaining, &missed); err != nil {
		t.Fatal(err)
	}
	if missed != 4 {
		t.Errorf("missed_payments = %d, mau 4", missed)
	}
	// 4 denda x (10%% x 1000) = 400 di atas sisa 50000.
	if remaining != 50400 {
		t.Errorf("sisa pinjaman = %.2f, mau 50400 (50000 + 4x100 denda)", remaining)
	}
	if status != "defaulted" {
		t.Errorf("status = %q, mau defaulted", status)
	}
	var grounded int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM fleet_aircraft WHERE id=$1 AND status='grounded'`, aircraftID).Scan(&grounded); err != nil {
		t.Fatal(err)
	}
	if grounded != 1 {
		t.Error("jaminan tidak di-groundkan setelah default")
	}
}

// TestProcessAircraftFinancingRepossessesAfterThree — financing punya ambang
// lebih ketat: denda 5%, repossess setelah 3 kali menunggak.
func TestProcessAircraftFinancingRepossessesAfterThree(t *testing.T) {
	ctx, pool, eng := testEngine(t)
	uid := testPlayer(t, ctx, pool, "d2_financing_probe", 0)
	aircraftID := testAircraft(t, ctx, pool, uid, "D2Z003")

	if _, err := pool.Exec(ctx, `
		INSERT INTO loans (user_id, principal, remaining_balance, weekly_payment, status, loan_type, collateral_aircraft_id)
		VALUES ($1, 100000, 50000, 1000, 'active', 'aircraft_financing', $2)`, uid, aircraftID); err != nil {
		t.Fatalf("insert loan: %v", err)
	}

	gameDate := time.Now().UTC()
	for i := 0; i < 3; i++ {
		eng.ProcessAircraftFinancingPayments(ctx, uid, gameDate)
	}

	var status string
	var remaining float64
	var missed int
	if err := pool.QueryRow(ctx, `SELECT status, remaining_balance, missed_payments FROM loans WHERE user_id=$1`, uid).Scan(&status, &remaining, &missed); err != nil {
		t.Fatal(err)
	}
	if missed != 3 {
		t.Errorf("missed_payments = %d, mau 3", missed)
	}
	// 3 denda x (5%% x 1000) = 150 di atas sisa 50000.
	if remaining != 50150 {
		t.Errorf("sisa pinjaman = %.2f, mau 50150 (50000 + 3x50 denda)", remaining)
	}
	if status != "repossessed" {
		t.Errorf("status = %q, mau repossessed", status)
	}
	var grounded int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM fleet_aircraft WHERE id=$1 AND status='grounded'`, aircraftID).Scan(&grounded); err != nil {
		t.Fatal(err)
	}
	if grounded != 1 {
		t.Error("pesawat tidak di-groundkan setelah repossess")
	}
}

// TestWorldTickSmoke — jalur end-to-end tick: season clock dimajukan, satu baris
// world_tick_log 'success' tercatat UNTUK TICK INI, dan hasil mengembalikan waktu
// game. Catatan: WorldTick memajukan current_game_time season aktif secara
// permanen dan (bila melewati batas hari game) menjalankan retensi — test ini
// hanya untuk database sekali-pakai (TEST_DATABASE_URL).
func TestWorldTickSmoke(t *testing.T) {
	ctx, pool, eng := testEngine(t)

	var seasonID string
	var before time.Time
	if err := pool.QueryRow(ctx, `SELECT id, current_game_time FROM season_clock WHERE status='active'`).Scan(&seasonID, &before); err != nil {
		t.Fatalf("tidak ada season aktif (migrasi 24 belum jalan?): %v", err)
	}
	t.Cleanup(func() {
		_, _ = pool.Exec(ctx, `UPDATE season_clock SET current_game_time=$1 WHERE id=$2`, before, seasonID)
	})

	res, err := eng.WorldTick(ctx)
	if err != nil {
		t.Fatalf("WorldTick: %v", err)
	}
	if res.TicksProcessed != 1 {
		t.Fatalf("TicksProcessed = %d, mau 1", res.TicksProcessed)
	}

	var after time.Time
	if err := pool.QueryRow(ctx, `SELECT current_game_time FROM season_clock WHERE id=$1`, seasonID).Scan(&after); err != nil {
		t.Fatal(err)
	}
	if !after.After(before) {
		t.Errorf("season clock tidak maju: before=%s after=%s", before, after)
	}
	if res.GameTimeAfter != after.Format(time.RFC3339) {
		t.Errorf("GameTimeAfter = %q, mau %q", res.GameTimeAfter, after.Format(time.RFC3339))
	}

	// Baris MILIK tick ini, bukan tick lain yang kebetulan ada.
	var status string
	if err := pool.QueryRow(ctx, `
		SELECT status FROM world_tick_log
		WHERE season_id=$1 AND game_time_after=$2
		ORDER BY finished_at DESC LIMIT 1`, seasonID, after).Scan(&status); err != nil {
		t.Fatalf("baris world_tick_log untuk tick ini tidak ditemukan: %v", err)
	}
	if status != "success" {
		// 'degraded' berarti ada pemain REAL yang gagal diproses. Kalau ini muncul
		// tanpa sebab jelas, curigai DB bersama: paket lain membuat/menghapus user
		// sementara tick berjalan → jalankan paket ber-DB serial (`go test -p 1 ./...`).
		t.Errorf("status tick = %q, mau success (pemain gagal? paket ber-DB harus serial: -p 1)", status)
	}
}

// TestApplyBankruptcyRollsBackOnFailure — bukti atomicity: bila salah satu langkah
// gagal, TIDAK ada perubahan yang tersisa. Dulu empat Exec terpisah dengan error
// dibuang bisa meninggalkan pemain setengah-bangkrut.
func TestApplyBankruptcyRollsBackOnFailure(t *testing.T) {
	ctx, pool, eng := testEngine(t)

	// Injeksi kegagalan memakai DDL (CREATE/DROP TRIGGER). DROP TRIGGER butuh
	// kepemilikan tabel; role aplikasi (skyward_app) punya privilege TRIGGER
	// sehingga bisa MEMBUAT tapi tidak bisa MENGHAPUS → trigger akan tertinggal
	// permanen dan mematahkan test lain. Jadi test ini hanya jalan bila role test
	// memiliki tabelnya (CI memakai superuser). Dicek lebih dulu, sebelum menulis
	// apa pun, supaya skip tak meninggalkan sisa.
	var owner, current string
	if err := pool.QueryRow(ctx, `
		SELECT pg_get_userbyid(relowner) FROM pg_class WHERE oid='route_assignments'::regclass`).Scan(&owner); err != nil {
		t.Fatal(err)
	}
	if err := pool.QueryRow(ctx, `SELECT current_user`).Scan(&current); err != nil {
		t.Fatal(err)
	}
	if owner != current {
		t.Skipf("butuh pemilik tabel route_assignments untuk injeksi trigger (owner=%s, role=%s)", owner, current)
	}

	uid := testPlayer(t, ctx, pool, "d2_bankruptcy_rollback_probe", 5000)
	aircraftID := testAircraft(t, ctx, pool, uid, "D2Z004")

	if _, err := pool.Exec(ctx, `
		INSERT INTO loans (user_id, principal, remaining_balance, weekly_payment, status, loan_type, collateral_aircraft_id)
		VALUES ($1, 100000, 50000, 1000, 'active', 'unsecured', $2)`, uid, aircraftID); err != nil {
		t.Fatalf("insert loan: %v", err)
	}
	if _, err := pool.Exec(ctx, `
		INSERT INTO route_assignments (user_id, origin_iata, destination_iata, distance_km, ticket_price, status)
		VALUES ($1, 'SIN', 'KUL', 300, 120, 'active')`, uid); err != nil {
		t.Fatalf("insert route: %v", err)
	}
	// Trigger yang memaksa langkah TERAKHIR (cancel routes) gagal, supaya tiga
	// UPDATE sebelumnya harus di-rollback.
	dropInject := func() {
		if _, err := pool.Exec(ctx, `DROP TRIGGER IF EXISTS d2_fail_route_update_trg ON route_assignments`); err != nil {
			t.Errorf("bersihkan trigger inject: %v", err)
		}
		if _, err := pool.Exec(ctx, `DROP FUNCTION IF EXISTS d2_fail_route_update()`); err != nil {
			t.Errorf("bersihkan fungsi inject: %v", err)
		}
	}
	dropInject() // bersihkan sisa run yang mati di tengah
	t.Cleanup(dropInject)
	if _, err := pool.Exec(ctx, `CREATE OR REPLACE FUNCTION d2_fail_route_update() RETURNS trigger AS $$
		BEGIN RAISE EXCEPTION 'd2 injected failure'; END $$ LANGUAGE plpgsql;`); err != nil {
		t.Fatalf("buat fungsi trigger: %v", err)
	}
	if _, err := pool.Exec(ctx, `CREATE TRIGGER d2_fail_route_update_trg BEFORE UPDATE ON route_assignments
		FOR EACH ROW EXECUTE FUNCTION d2_fail_route_update();`); err != nil {
		t.Fatalf("pasang trigger: %v", err)
	}

	eng.applyBankruptcy(ctx, uid)

	var status string
	if err := pool.QueryRow(ctx, `SELECT operational_status FROM users WHERE id=$1`, uid).Scan(&status); err != nil {
		t.Fatal(err)
	}
	if status == "Bankrupt" {
		t.Error("status jadi Bankrupt padahal transaksi harus rollback")
	}
	var loanStatus string
	if err := pool.QueryRow(ctx, `SELECT status FROM loans WHERE user_id=$1`, uid).Scan(&loanStatus); err != nil {
		t.Fatal(err)
	}
	if loanStatus != "active" {
		t.Errorf("pinjaman = %q, mau tetap active (rollback)", loanStatus)
	}
	var grounded int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM fleet_aircraft WHERE user_id=$1 AND status='grounded'`, uid).Scan(&grounded); err != nil {
		t.Fatal(err)
	}
	if grounded != 0 {
		t.Errorf("armada grounded = %d, mau 0 (rollback)", grounded)
	}
}

// TestProcessLoanPaymentsPaysOffWhenSettled — angsuran terakhir menutup pinjaman:
// status jadi paid_off dan sisa nol (bukan dibiarkan aktif dengan sisa kecil).
func TestProcessLoanPaymentsPaysOffWhenSettled(t *testing.T) {
	ctx, pool, eng := testEngine(t)
	uid := testPlayer(t, ctx, pool, "d2_loan_paidoff_probe", 10000)

	if _, err := pool.Exec(ctx, `
		INSERT INTO loans (user_id, principal, remaining_balance, weekly_payment, status, loan_type)
		VALUES ($1, 1000, 1000, 1000, 'active', 'unsecured')`, uid); err != nil {
		t.Fatalf("insert loan: %v", err)
	}

	eng.ProcessLoanPayments(ctx, uid, time.Now().UTC())

	var status string
	var remaining float64
	if err := pool.QueryRow(ctx, `SELECT status, remaining_balance FROM loans WHERE user_id=$1`, uid).Scan(&status, &remaining); err != nil {
		t.Fatal(err)
	}
	if remaining != 0 || status != "paid_off" {
		t.Errorf("loan = (%q, %.2f), mau (paid_off, 0)", status, remaining)
	}
	var balance float64
	if err := pool.QueryRow(ctx, `SELECT COALESCE(balance,0) FROM bank_accounts WHERE user_id=$1 AND account_type='operating'`, uid).Scan(&balance); err != nil {
		t.Fatal(err)
	}
	if balance != 9000 {
		t.Errorf("saldo = %.2f, mau 9000", balance)
	}
}

// TestLoanPaymentTypeIsolation — tiap proses hanya menagih tipe pinjamannya
// sendiri; regresi pada filter loan_type akan menagih dua kali.
func TestLoanPaymentTypeIsolation(t *testing.T) {
	ctx, pool, eng := testEngine(t)
	uid := testPlayer(t, ctx, pool, "d2_loan_isolation_probe", 100000)

	var unsecuredID, financingID string
	if err := pool.QueryRow(ctx, `
		INSERT INTO loans (user_id, principal, remaining_balance, weekly_payment, status, loan_type)
		VALUES ($1, 100000, 50000, 2000, 'active', 'unsecured') RETURNING id`, uid).Scan(&unsecuredID); err != nil {
		t.Fatalf("insert unsecured: %v", err)
	}
	if err := pool.QueryRow(ctx, `
		INSERT INTO loans (user_id, principal, remaining_balance, weekly_payment, status, loan_type)
		VALUES ($1, 100000, 50000, 3000, 'active', 'aircraft_financing') RETURNING id`, uid).Scan(&financingID); err != nil {
		t.Fatalf("insert financing: %v", err)
	}

	gameDate := time.Now().UTC()
	eng.ProcessLoanPayments(ctx, uid, gameDate)
	eng.ProcessAircraftFinancingPayments(ctx, uid, gameDate)

	var unsecuredRemaining, financingRemaining float64
	if err := pool.QueryRow(ctx, `SELECT remaining_balance FROM loans WHERE id=$1`, unsecuredID).Scan(&unsecuredRemaining); err != nil {
		t.Fatal(err)
	}
	if err := pool.QueryRow(ctx, `SELECT remaining_balance FROM loans WHERE id=$1`, financingID).Scan(&financingRemaining); err != nil {
		t.Fatal(err)
	}
	if unsecuredRemaining != 48000 {
		t.Errorf("unsecured = %.2f, mau 48000 (hanya ditagih sekali)", unsecuredRemaining)
	}
	if financingRemaining != 47000 {
		t.Errorf("financing = %.2f, mau 47000 (hanya ditagih sekali)", financingRemaining)
	}
}

// TestWriteTickLogRecordsDegraded — tick dengan kegagalan harus tercatat
// 'degraded'. Sebelum migrasi 26, CHECK constraint menolak 'degraded' sehingga
// INSERT gagal senyap dan tick terdegradasi tak pernah terekam.
func TestWriteTickLogRecordsDegraded(t *testing.T) {
	ctx, pool, eng := testEngine(t)

	var seasonID string
	if err := pool.QueryRow(ctx, `SELECT id FROM season_clock WHERE status='active'`).Scan(&seasonID); err != nil {
		t.Fatalf("tidak ada season aktif: %v", err)
	}
	before := time.Now().UTC()
	after := before.Add(time.Hour)
	t.Cleanup(func() {
		_, _ = pool.Exec(ctx, `DELETE FROM world_tick_log WHERE season_id=$1 AND game_time_after=$2`, seasonID, after)
	})

	eng.writeTickLog(ctx, seasonID, before, after, 0, 0, 1 /* failed */)

	var status string
	if err := pool.QueryRow(ctx, `
		SELECT status FROM world_tick_log
		WHERE season_id=$1 AND game_time_after=$2
		ORDER BY finished_at DESC LIMIT 1`, seasonID, after).Scan(&status); err != nil {
		t.Fatalf("baris degraded tidak tercatat (CHECK masih menolak 'degraded'?): %v", err)
	}
	if status != "degraded" {
		t.Errorf("status = %q, mau degraded", status)
	}
}
