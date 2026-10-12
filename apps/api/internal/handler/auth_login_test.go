package handler

import (
	"net/http"
	"net/http/httptest"
	"strconv"
	"strings"
	"testing"
	"time"

	"skyward-api/internal/middleware"
)

// TestLoginRateLimited — tamu yang menghabiskan bucket username dapat 429, dan
// Retry-After mencerminkan sisa window (bukan "1" seperti sebelumnya).
//
// Butuh DB: Login menormalkan username lewat store sebelum menghitung bucket
// (supaya variasi huruf besar/spasi tidak mendapat bucket terpisah), jadi test
// ini di-skip bila `TEST_DATABASE_URL` tidak diset.
func TestLoginRateLimited(t *testing.T) {
	const window = time.Minute
	h, _ := newAuthHandlerDB(t)
	h.LoginLimiter = middleware.NewWindowLimiter(window, 0)

	// Habiskan bucket username (10). Handler akan menolak sebelum lookup.
	for i := 0; i < 10; i++ {
		if !h.LoginLimiter.Allow("login:u:fredi", 10) {
			t.Fatalf("Allow ke-%d ditolak terlalu dini", i+1)
		}
	}

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/auth/login",
		strings.NewReader(`{"username":"fredi","password":"x"}`))
	h.Login(rec, req)

	if rec.Code != http.StatusTooManyRequests {
		t.Fatalf("status = %d, mau 429", rec.Code)
	}
	secs, err := strconv.Atoi(rec.Header().Get("Retry-After"))
	if err != nil {
		t.Fatalf("Retry-After %q bukan integer: %v", rec.Header().Get("Retry-After"), err)
	}
	if secs <= 1 || secs > int(window.Seconds()) {
		t.Errorf("Retry-After = %d, mau di antara 2..%d", secs, int(window.Seconds()))
	}

	// Variasi huruf besar harus masuk bucket yang SAMA (bukan bucket terpisah).
	rec = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodPost, "/auth/login",
		strings.NewReader(`{"username":"FREDI","password":"x"}`))
	h.Login(rec, req)
	if rec.Code != http.StatusTooManyRequests {
		t.Errorf("username huruf besar = %d, mau 429 (bucket harus ternormalisasi)", rec.Code)
	}
}
