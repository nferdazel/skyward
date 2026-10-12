package middleware

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func corsHandler(origin string) *httptest.ResponseRecorder {
	handler := CORS([]string{"https://skyward.qouver.com"})(
		http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) }),
	)
	req := httptest.NewRequest(http.MethodGet, "/fleet", nil)
	req.Header.Set("Origin", origin)
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, req)
	return rec
}

func TestCORSAllowsConfiguredOrigin(t *testing.T) {
	rec := corsHandler("https://skyward.qouver.com")

	if got := rec.Header().Get("Access-Control-Allow-Origin"); got != "https://skyward.qouver.com" {
		t.Fatalf("Allow-Origin = %q", got)
	}
	allow := rec.Header().Get("Access-Control-Allow-Headers")
	for _, want := range []string{"Authorization", "Content-Type", "If-Match"} {
		if !strings.Contains(allow, want) {
			t.Errorf("Allow-Headers tidak memuat %s: %q", want, allow)
		}
	}
	// Header era Supabase tidak dipakai lagi oleh klien mana pun; kalau muncul
	// kembali berarti ada permintaan yang menyalinnya balik ke daftar ini.
	for _, legacy := range []string{"apikey", "x-client-info", "prefer", "user-agent"} {
		if strings.Contains(strings.ToLower(allow), legacy) {
			t.Errorf("Allow-Headers masih memuat header legacy %s: %q", legacy, allow)
		}
	}
}

func TestCORSRejectsUnknownOrigin(t *testing.T) {
	rec := corsHandler("https://evil.example")

	if got := rec.Header().Get("Access-Control-Allow-Origin"); got != "" {
		t.Fatalf("origin tak dikenal dapat Allow-Origin %q", got)
	}
}
