package handler

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/jackc/pgx/v5"
)

func TestWriteNotFoundOrInternal(t *testing.T) {
	cases := []struct {
		name     string
		err      error
		wantCode string
		wantHTTP int
	}{
		{"no rows → 404", pgx.ErrNoRows, "not_found", http.StatusNotFound},
		{"no rows terbalut → 404", fmt.Errorf("lookup: %w", pgx.ErrNoRows), "not_found", http.StatusNotFound},
		{"error lain → 500 (tidak dimask)", errors.New("connection reset"), "internal", http.StatusInternalServerError},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			writeNotFoundOrInternal(rec, tc.err, "not found", "internal")
			if rec.Code != tc.wantHTTP {
				t.Fatalf("status = %d, want %d", rec.Code, tc.wantHTTP)
			}
			var body struct {
				Error struct {
					Code    string `json:"code"`
					Message string `json:"message"`
				} `json:"error"`
			}
			if err := json.NewDecoder(rec.Body).Decode(&body); err != nil {
				t.Fatalf("decode body: %v", err)
			}
			if body.Error.Code != tc.wantCode {
				t.Fatalf("error.code = %q, want %q", body.Error.Code, tc.wantCode)
			}
		})
	}
}

// TestReadHandlersRejectUnauthenticated — tiap handler ber-userID harus menolak
// request tanpa user context (401) SEBELUM menyentuh store. Store nil: kalau
// handler kurang gerbang, test ini panic/500 alih-alih 401.
func TestReadHandlersRejectUnauthenticated(t *testing.T) {
	h := &ReadHandler{}
	handlers := map[string]func(http.ResponseWriter, *http.Request){
		"SimulationState":         h.SimulationState,
		"Achievements":            h.Achievements,
		"Fleet":                   h.Fleet,
		"Routes":                  h.Routes,
		"FinanceSnapshot":         h.FinanceSnapshot,
		"FinanceTransactions":     h.FinanceTransactions,
		"BankLoans":               h.BankLoans,
		"BankCredit":              h.BankCredit,
		"FleetAvailable":          h.FleetAvailable,
		"FleetByID":               h.FleetByID,
		"FleetLatestForModel":     h.FleetLatestForModel,
		"GroundingThreshold":      h.GroundingThreshold,
		"FinanceHistory":          h.FinanceHistory,
		"BankCreditHistory":       h.BankCreditHistory,
		"BankAccounts":            h.BankAccounts,
		"BankTransactionsByAccId": h.BankTransactionsByAccount,
	}
	for name, fn := range handlers {
		t.Run(name, func(t *testing.T) {
			rec := httptest.NewRecorder()
			fn(rec, httptest.NewRequest(http.MethodGet, "/x", nil))
			if rec.Code != http.StatusUnauthorized {
				t.Fatalf("status = %d, want 401", rec.Code)
			}
		})
	}
}
