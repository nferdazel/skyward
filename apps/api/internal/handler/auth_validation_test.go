package handler

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// TestAuthValidationRejectsBeforeStore — validasi body dan panjang password
// terjadi SEBELUM handler menyentuh store, jadi bisa diuji tanpa DB. Handler
// sengaja dibangun dengan Store nil: kalau urutan validasi bocor dan store
// terpanggil, test ini panic alih-alih lolos diam-diam.
func TestAuthValidationRejectsBeforeStore(t *testing.T) {
	h := &AuthHandler{}

	cases := []struct {
		name string
		fn   http.HandlerFunc
		body string
	}{
		{"register: body bukan JSON", h.Register, `{bukan json`},
		{"register: password < 6", h.Register, `{"username":"a","password":"12345","companyName":"C","ceoName":"D"}`},
		{"register: username kosong", h.Register, `{"username":" ","password":"123456","companyName":"C","ceoName":"D"}`},
		{"register: companyName kosong", h.Register, `{"username":"a","password":"123456","companyName":" ","ceoName":"D"}`},
		{"register: ceoName kosong", h.Register, `{"username":"a","password":"123456","companyName":"C","ceoName":" "}`},
		{"login: body bukan JSON", h.Login, `{bukan json`},
		{"reset: body bukan JSON", h.ResetPassword, `{bukan json`},
		{"reset: password baru < 6", h.ResetPassword, `{"username":"a","newPassword":"12345"}`},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			req := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(tc.body))
			tc.fn(rec, req)
			if rec.Code != http.StatusBadRequest {
				t.Fatalf("status = %d, mau 400 (body: %s)", rec.Code, rec.Body.String())
			}
		})
	}
}
