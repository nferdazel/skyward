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

func TestRegisterRateLimited(t *testing.T) {
	h := &AuthHandler{RegisterLimiter: middleware.NewWindowLimiter(time.Minute, 0)}

	// Body kosong: decode sukses lalu validasi menolak (400). Limiter dihitung
	// sebelum validasi, jadi tidak perlu store/DB.
	do := func() int {
		rec := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodPost, "/auth/register", strings.NewReader(`{}`))
		h.Register(rec, req)
		return rec.Code
	}

	for i := 1; i <= 10; i++ {
		if code := do(); code == http.StatusTooManyRequests {
			t.Fatalf("attempt %d limited too early (code %d)", i, code)
		}
	}
	if code := do(); code != http.StatusTooManyRequests {
		t.Fatalf("11th attempt = %d, want 429", code)
	}

	// 429 harus membawa Retry-After sisa window, bukan "1" tetap — klien yang
	// retry tiap detik akan kena 429 lagi selama window 15 menit.
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/auth/register", strings.NewReader(`{}`))
	h.Register(rec, req)
	if rec.Code != http.StatusTooManyRequests {
		t.Fatalf("limited attempt = %d, want 429", rec.Code)
	}
	ra, err := strconv.Atoi(rec.Header().Get("Retry-After"))
	if err != nil || ra <= 1 {
		t.Fatalf("Retry-After = %q, want integer > 1", rec.Header().Get("Retry-After"))
	}

	// IP berbeda punya budget terpisah: key harus mencakup IP, bukan konstan.
	rec = httptest.NewRecorder()
	req = httptest.NewRequest(http.MethodPost, "/auth/register", strings.NewReader(`{}`))
	req.RemoteAddr = "198.51.100.99:5000"
	h.Register(rec, req)
	if rec.Code == http.StatusTooManyRequests {
		t.Fatal("IP berbeda tidak boleh terkena limit IP lain")
	}
}
