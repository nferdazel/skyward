package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"skyward-api/internal/middleware"
	"skyward-api/internal/store"
)

// Test handler dengan STORE NYATA (butuh database hasil migrasi); di-skip bila
// `TEST_DATABASE_URL` tidak diset — sama seperti test DB lain di repo.

func newAuthHandlerDB(t *testing.T) (*AuthHandler, *pgxpool.Pool) {
	t.Helper()
	dbURL := os.Getenv("TEST_DATABASE_URL")
	if dbURL == "" {
		t.Skip("TEST_DATABASE_URL tidak diset; test ini butuh database hasil `make migrate`")
	}
	pool, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	// Secret wajib >= 32 byte (auth.Sign menolaknya).
	return &AuthHandler{
		Store:     store.New(pool),
		JWTSecret: []byte("d1-test-secret-0123456789abcdefghijklmnop"),
	}, pool
}

// postAuth mengirim body JSON yang benar-benar di-marshal — nilai yang
// mengandung spasi/kutip tidak perlu (dan tidak boleh) dirangkai manual ke JSON.
func postAuth(t *testing.T, h http.HandlerFunc, path string, payload map[string]string) *httptest.ResponseRecorder {
	t.Helper()
	raw, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("marshal payload: %v", err)
	}
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, path, bytes.NewReader(raw))
	h(rec, req)
	return rec
}

// registerProbe mendaftarkan satu user probe, membersihkan residu run yang mati
// di tengah (username DAN company_name sama-sama UNIQUE — tepat dua nilai, tanpa
// LIKE, supaya tidak menghapus baris milik test lain), lalu membersihkan
// barisnya sendiri by id.
func registerProbe(t *testing.T, h *AuthHandler, pool *pgxpool.Pool, username, company, password string) authResponse {
	t.Helper()
	ctx := context.Background()
	if _, err := pool.Exec(ctx,
		`DELETE FROM users WHERE username = public.normalize_username($1) OR company_name = $2`,
		username, company); err != nil {
		t.Fatal(err)
	}

	rec := postAuth(t, h.Register, "/auth/register", map[string]string{
		"username": username, "password": password,
		"companyName": company, "ceoName": "D1 Tester",
	})
	if rec.Code != http.StatusCreated {
		t.Fatalf("register(%q) = %d, mau 201 (body: %s)", username, rec.Code, rec.Body.String())
	}
	var reg authResponse
	if err := json.NewDecoder(rec.Body).Decode(&reg); err != nil {
		t.Fatalf("decode register: %v", err)
	}
	if reg.Token == "" || reg.User.ID == "" {
		t.Fatalf("respond register tak lengkap: %+v", reg)
	}
	t.Cleanup(func() {
		if _, err := pool.Exec(context.Background(), `DELETE FROM users WHERE id=$1`, reg.User.ID); err != nil {
			t.Logf("cleanup user %s: %v", reg.User.ID, err)
		}
	})
	return reg
}

// TestRegisterLoginMeRoundTrip — jalur penuh dengan store nyata:
// register 201 → login 200 → GET /auth/me lewat AuthGuard 200.
func TestRegisterLoginMeRoundTrip(t *testing.T) {
	h, pool := newAuthHandlerDB(t)
	reg := registerProbe(t, h, pool, "d1_handler_roundtrip", "D1 Roundtrip Air", "secret123")

	rec := postAuth(t, h.Login, "/auth/login", map[string]string{
		"username": reg.User.Username, "password": "secret123"})
	if rec.Code != http.StatusOK {
		t.Fatalf("login = %d, mau 200 (body: %s)", rec.Code, rec.Body.String())
	}
	var login authResponse
	if err := json.NewDecoder(rec.Body).Decode(&login); err != nil {
		t.Fatalf("decode login: %v", err)
	}
	if login.Token == "" || login.User.ID != reg.User.ID {
		t.Fatalf("login tidak mengembalikan user yang sama: %+v", login.User)
	}

	rec = httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+login.Token)
	middleware.AuthGuard(h.JWTSecret, h.Me)(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("/auth/me = %d, mau 200 (body: %s)", rec.Code, rec.Body.String())
	}
	var me userJSON
	if err := json.NewDecoder(rec.Body).Decode(&me); err != nil {
		t.Fatalf("decode me: %v", err)
	}
	// company_name lewat /auth/me membuktikan persistensinya lewat query
	// terpisah, bukan sekadar mengulang response register.
	if me.ID != reg.User.ID || me.Username != reg.User.Username || me.CompanyName != "D1 Roundtrip Air" {
		t.Errorf("/auth/me = %+v, mau user %s", me, reg.User.ID)
	}
}

// TestLoginFailureResponseIsIdentical — password salah dan username tak dikenal
// harus menghasilkan 401 yang IDENTIK byte-per-byte, bukan hanya status yang
// sama: pesan yang berbeda = kebocoran username mana yang ada.
func TestLoginFailureResponseIsIdentical(t *testing.T) {
	h, pool := newAuthHandlerDB(t)
	reg := registerProbe(t, h, pool, "d1_handler_enum", "D1 Enum Air", "secret123")

	wrongPass := postAuth(t, h.Login, "/auth/login", map[string]string{
		"username": reg.User.Username, "password": "bukan-password-ini"})
	unknown := postAuth(t, h.Login, "/auth/login", map[string]string{
		"username": "d1_tidak_ada_siapa", "password": "secret123"})

	if wrongPass.Code != http.StatusUnauthorized || unknown.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d/%d, mau 401/401", wrongPass.Code, unknown.Code)
	}
	if wrongPass.Body.String() != unknown.Body.String() {
		t.Errorf("body berbeda:\n password salah: %s\n user tak dikenal: %s",
			wrongPass.Body.String(), unknown.Body.String())
	}
	if a, b := wrongPass.Header().Get("Content-Type"), unknown.Header().Get("Content-Type"); a != b {
		t.Errorf("Content-Type berbeda: %q vs %q", a, b)
	}
}

// TestRegisterNormalizesUsernameAndLoginFindsIt — username DISIMPAN sebagai slug
// (parity dengan `normalize_username` SQL, seperti era Supabase), dan login harus
// menemukan akun itu walau pemain mengetik ulang bentuk mentahnya. Sebelum
// perbaikan, lookup login membandingkan string mentah → pemain terkunci.
func TestRegisterNormalizesUsernameAndLoginFindsIt(t *testing.T) {
	h, pool := newAuthHandlerDB(t)

	const raw = " D1 Handler Round trip "
	const want = "d1-handler-round-trip" // spasi → '-', huruf kecil, '-' tepi dibuang

	reg := registerProbe(t, h, pool, raw, "D1 Normalisasi Air", "secret123")
	if reg.User.Username != want {
		t.Fatalf("username tersimpan = %q, mau %q", reg.User.Username, want)
	}

	rec := postAuth(t, h.Login, "/auth/login", map[string]string{
		"username": raw, "password": "secret123"})
	if rec.Code != http.StatusOK {
		t.Fatalf("login dengan input mentah = %d, mau 200 (body: %s)", rec.Code, rec.Body.String())
	}

	// Username yang normalisasinya kosong ditolak 400, bukan 500.
	rec = postAuth(t, h.Register, "/auth/register", map[string]string{
		"username": "###", "password": "secret123",
		"companyName": "D1 Normalisasi Kosong", "ceoName": "D1"})
	if rec.Code != http.StatusBadRequest {
		t.Errorf("register username '###' = %d, mau 400 (body: %s)", rec.Code, rec.Body.String())
	}
}

// TestRegisterDuplicateRejected — 400 untuk username yang sama DAN untuk company
// yang sama (ErrUsernameTaken menangkap 23505 dari kedua constraint unik).
func TestRegisterDuplicateRejected(t *testing.T) {
	h, pool := newAuthHandlerDB(t)
	registerProbe(t, h, pool, "d1_handler_dupe", "D1 Dupe Satu", "secret123")

	rec := postAuth(t, h.Register, "/auth/register", map[string]string{
		"username": "d1_handler_dupe", "password": "secret123",
		"companyName": "D1 Dupe Dua", "ceoName": "B"})
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("duplikat username = %d, mau 400 (body: %s)", rec.Code, rec.Body.String())
	}

	// Company yang sudah dipakai, username baru → tetap 400.
	rec = postAuth(t, h.Register, "/auth/register", map[string]string{
		"username": "d1_handler_dupe_lain", "password": "secret123",
		"companyName": "D1 Dupe Satu", "ceoName": "C"})
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("duplikat company = %d, mau 400 (body: %s)", rec.Code, rec.Body.String())
	}
}

// TestLoginSuccessClearsNormalizedBucket — regresi: kunci `Clear` harus SAMA
// dengan kunci bucket. Sebelum diperbaiki, `Clear` memakai input mentah sementara
// bucket memakai nilai ternormalisasi, sehingga pemain yang mengetik spasi/huruf
// besar tetap kehabisan kuota meski loginnya baru saja berhasil.
func TestLoginSuccessClearsNormalizedBucket(t *testing.T) {
	h, pool := newAuthHandlerDB(t)
	h.LoginLimiter = middleware.NewWindowLimiter(15*time.Minute, 0)

	// Username disimpan sebagai slug, jadi login boleh diketik bebas gaya.
	reg := registerProbe(t, h, pool, "d1 Handler Clear", "D1 Clear Air", "benar-secret")
	if reg.User.Username != "d1-handler-clear" {
		t.Fatalf("username tersimpan = %q, mau d1-handler-clear", reg.User.Username)
	}

	const typed = "D1 HANDLER clear" // bentuk mentah; normalisasi → slug yang sama
	for i := 1; i <= 9; i++ {
		rec := postAuth(t, h.Login, "/auth/login", map[string]string{"username": typed, "password": "salah"})
		if rec.Code != http.StatusUnauthorized {
			t.Fatalf("percobaan gagal ke-%d = %d, mau 401 (body: %s)", i, rec.Code, rec.Body.String())
		}
	}

	// Percobaan ke-10 sukses (kuota pas 10) dan WAJIB mengosongkan bucket.
	rec := postAuth(t, h.Login, "/auth/login", map[string]string{"username": typed, "password": "benar-secret"})
	if rec.Code != http.StatusOK {
		t.Fatalf("login sukses = %d, mau 200 (body: %s)", rec.Code, rec.Body.String())
	}
	// Kalau `Clear` memakai kunci lain (input mentah), percobaan berikutnya 429.
	rec = postAuth(t, h.Login, "/auth/login", map[string]string{"username": typed, "password": "benar-secret"})
	if rec.Code != http.StatusOK {
		t.Errorf("percobaan setelah login sukses = %d, mau 200 (bucket tidak ter-clear?)", rec.Code)
	}
}

// TestResetPasswordChangesCredentials — klaim AUDIT-01 yang belum pernah
// dibuktikan di DB: setelah reset, password BARU bisa login dan password LAMA
// tidak. Faktor recovery yang salah harus 401 TANPA mengubah apa pun.
//
// Register tidak mengisi HQ (users.hq_airport_iata NULL), dan recovery
// fail-closed saat HQ kosong — jadi HQ diisi lewat SQL dulu, seperti onboarding.
func TestResetPasswordChangesCredentials(t *testing.T) {
	h, pool := newAuthHandlerDB(t)
	ctx := context.Background()

	reg := registerProbe(t, h, pool, "d1_handler_reset", "D1 Reset Air", "lama-secret")
	if _, err := pool.Exec(ctx, `UPDATE users SET hq_airport_iata='SIN' WHERE id=$1`, reg.User.ID); err != nil {
		t.Fatalf("set HQ: %v", err)
	}

	good := map[string]string{
		"username":      reg.User.Username,
		"newPassword":   "baru-secret",
		"companyName":   "D1 Reset Air",
		"ceoName":       "D1 Tester",
		"hqAirportIata": "SIN",
	}

	// Faktor salah (company beda) → 401 dan password lama tetap berlaku.
	bad := map[string]string{}
	for k, v := range good {
		bad[k] = v
	}
	bad["companyName"] = "Bukan Company Ini"
	if rec := postAuth(t, h.ResetPassword, "/auth/reset-password", bad); rec.Code != http.StatusUnauthorized {
		t.Fatalf("reset dengan faktor salah = %d, mau 401 (body: %s)", rec.Code, rec.Body.String())
	}
	rec := postAuth(t, h.Login, "/auth/login", map[string]string{
		"username": reg.User.Username, "password": "lama-secret"})
	if rec.Code != http.StatusOK {
		t.Errorf("password lama harusnya masih berlaku setelah reset gagal, dapat %d", rec.Code)
	}

	// Faktor benar → 200; password baru berlaku, password lama tidak.
	rec = postAuth(t, h.ResetPassword, "/auth/reset-password", good)
	if rec.Code != http.StatusOK {
		t.Fatalf("reset = %d, mau 200 (body: %s)", rec.Code, rec.Body.String())
	}
	rec = postAuth(t, h.Login, "/auth/login", map[string]string{
		"username": reg.User.Username, "password": "baru-secret"})
	if rec.Code != http.StatusOK {
		t.Errorf("login dengan password baru = %d, mau 200 (body: %s)", rec.Code, rec.Body.String())
	}
	rec = postAuth(t, h.Login, "/auth/login", map[string]string{
		"username": reg.User.Username, "password": "lama-secret"})
	if rec.Code != http.StatusUnauthorized {
		t.Errorf("password lama masih bisa login setelah reset: %d, mau 401", rec.Code)
	}
}
