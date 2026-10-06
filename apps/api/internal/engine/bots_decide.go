// Package engine — bot decision helpers (murni, tanpa DB).
//
// Dipisah dari bots.go (B3): fungsi di sini tidak menyentuh *Engine maupun
// database, sehingga mudah diuji dalam isolasi. Tidak ada perubahan perilaku.
package engine

import (
	"fmt"
	"math"
	"math/rand"
)

func nullableSeason(seasonID string) *string {
	if seasonID == "" {
		return nil
	}
	return &seasonID
}

// routeCandidate — satu rute yang mungkin dibuka bot, dengan estimasi profit
// mingguan memakai model yang sama seperti audit rute (`routeWeeklyProfit`).
type routeCandidate struct {
	Dest       string
	DistanceKM float64
	DestDemand int
	Profit     float64
}

// routeCandidateMinProfit — ambang profit mingguan minimum supaya rute baru
// benar-benar menambah nilai, bukan sekadar mengisi slot. Rute yang cuma
// untung sepeser pun akan mengunci pesawat dan slot rute bot.
const routeCandidateMinProfit = 1000.0

// defaultSchedRatio dipakai saat menyesuaikan rute lama yang tidak membawa
// archetype-nya. Sama dengan schedRatio terbanyak supaya penyesuaian tidak
// agresif mengubah rute hanya karena kita tidak tahu profil bot-nya.
const defaultSchedRatio = 0.72

// pickBestRouteCandidate memilih kandidat dengan estimasi profit tertinggi.
// Mengembalikan ok=false kalau tidak ada yang melewati ambang — lebih baik bot
// tidak membuka rute daripada membuka rute rugi yang harus dihapus lagi nanti.
func pickBestRouteCandidate(cands []routeCandidate) (routeCandidate, bool) {
	var best routeCandidate
	found := false
	for _, c := range cands {
		if c.Profit < routeCandidateMinProfit {
			continue
		}
		if !found || c.Profit > best.Profit {
			best, found = c, true
		}
	}
	return best, found
}

// estimateRouteProfit — pembungkus tipis supaya pemilihan rute dan audit rute
// memakai satu perhitungan yang sama. Kalau keduanya berbeda, bot bisa memilih
// rute yang dianggap untung saat memilih tapi rugi saat diaudit (atau
// sebaliknya), dan siklus buka-hapus tidak pernah berhenti.
func estimateRouteProfit(p routePerfParams, c routePerfConfig) float64 {
	return routeWeeklyProfit(p, c)
}

// botTargetFlights — jumlah flight/minggu yang masuk akal untuk satu rute bot.
//
// Masalah yang diperbaiki: dulu bot memakai `calcMaxWeeklyFlights * SchedRatio`
// (mis. 0.72 x 75 = 54 flights/minggu). Itu kapasitas FISIK pesawat, bukan
// jumlah yang dibutuhkan. Demand pool rute 979 km pada harga reference hanya
// ~157 pax/hari, yang terangkut dalam ~6 flight/minggu dengan pesawat 180 kursi.
// Menerbangkan 54 flight membuat bot membayar fuel/crew/maintenance 9x lipat
// untuk penumpang yang sama; pendapatan mentok karena `allocateCabins` dibatasi
// pool. Itu sebabnya 4 dari 5 bot rugi seumur hidup di prod.
//
// Sekarang frekuensi dibatasi pada yang dibutuhkan demand (dengan margin kecil
// supaya load factor tinggi tapi rute tetap fleksibel), dan tidak pernah
// melewati kapasitas fisik.
func botTargetFlights(capacity int, dailyDemand float64, maxPhysical int, schedRatio float64) int {
	if capacity <= 0 || maxPhysical <= 0 {
		return 0
	}
	// Flight yang dibutuhkan untuk mengangkut seluruh pool (load factor ~100%).
	needed := dailyDemand * 7.0 / float64(capacity)
	// SchedRatio mengisi sebagian kapasitas: rasio rendah = load factor tinggi
	// (murah, tapi penumpang tertinggal), rasio tinggi = melayani lebih banyak
	// pool. Ambang 1.0 = tepat menutup seluruh pool.
	if schedRatio <= 0 {
		schedRatio = 0.72
	}
	target := int(math.Ceil(needed * schedRatio))
	// Minimal 1 flight/minggu supaya rute tetap hidup, dan jangan lewati
	// kapasitas fisik pesawat.
	if target < 1 {
		target = 1
	}
	if target > maxPhysical {
		target = maxPhysical
	}
	return target
}

// botRespondPrice — pure pricing decision for one bot route review (GAME-22).
// Blends the archetype/distress target fare with a decisive response to a
// cheaper competitor, so bots converge toward the market within 1-2 reviews.
func botRespondPrice(price, base, avgComp float64, compCount int, priceMult,
	compThreshold float64, archetype, distress string) float64 {
	adj := 0.97
	switch {
	case distress == "desperate":
		adj = 0.90
	case distress == "defensive":
		adj = 0.95
	case distress == "cautious":
		adj = 0.98
	case archetype == "Aggressive":
		adj = 1.01
	case archetype == "Balanced":
		adj = 1.03
	}
	newPrice := (price * 0.55) + (base * priceMult * adj * 0.45)
	if compCount > 0 && avgComp > 0 {
		switch {
		case price > avgComp*(1+compThreshold):
			// Undercut: undercut back, but never below the marginal base fare.
			// Move 65% of the way toward the target so the bot converges within
			// 1-2 reviews rather than drifting ~2% per cycle.
			target := math.Max(avgComp*0.98, base*0.9)
			newPrice = (price * 0.35) + (target * 0.65)
		case price < avgComp*(1-compThreshold):
			// We are the cheapest by a wide margin; raise toward (not past) the
			// competitor.
			target := avgComp * 0.99
			newPrice = (price * 0.70) + (target * 0.30)
		}
	}
	return newPrice
}

// generateCompanyName mirrors generate_company_name(archetype).
func generateCompanyName(archetype string) string {
	prefixes := []string{"Pacific", "Atlas", "Eagle", "Nova", "Apex", "Summit", "Horizon", "Zenith",
		"Sterling", "Phoenix", "Titan", "Vanguard", "Sovereign", "Pinnacle", "Crest",
		"Falcon", "Meridian", "Aurora", "Comet", "Star", "Sky", "Air", "Jet", "Swift"}
	suffixes := []string{"Airways", "Air", "Airlines", "Aviation", "Air Lines", "Express", "Air Services"}
	regional := []string{"Regional", "Air Express", "Commuter", "Air Link", "Connect"}
	premium := []string{"International", "World", "Global", "Airways International", "Premium"}

	name := prefixes[rand.Intn(len(prefixes))]
	switch archetype {
	case "Regional":
		name += " " + regional[rand.Intn(len(regional))]
	case "Aggressive":
		name += " " + suffixes[rand.Intn(len(suffixes))]
	case "Balanced":
		name += " " + premium[rand.Intn(len(premium))]
	default:
		name += " " + suffixes[rand.Intn(len(suffixes))]
	}
	return name
}

func randString(n int) string {
	const chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, n)
	for i := range b {
		b[i] = chars[rand.Intn(len(chars))]
	}
	return string(b)
}

func parseF(s string, def float64) float64 {
	var v float64
	if _, err := fmt.Sscanf(s, "%f", &v); err != nil {
		return def
	}
	return v
}

// routePerformance — weekly profit per active route for a bot. Uses the same
// demand-pool + cabin-allocation model as the player simulation (GAME-25);
// the legacy SQL get_route_performance is deprecated and unused.
type routePerf struct {
	RouteID string
	Profit  float64
	// Disimpan supaya pemanggil bisa menghitung ulang target frekuensi yang
	// sehat dari demand, bukan menebak atau mengurangi sedikit-sedikit.
	Params routePerfParams
	Config routePerfConfig
}

// routePerfParams — input untuk perhitungan ekonomi satu rute bot.
type routePerfParams struct {
	DistanceKM, TicketPrice, FlightsPerWeek        float64
	FuelBurnPerKM, SpeedKMH, MaintCostHr, Capacity float64
	TurnaroundHours                                float64
	OriginDemand, DestDemand                       int
	EconomySeats, BusinessSeats, FirstClassSeats   int
	AcqType                                        string
	LeasePriceMonth                                float64
}

// routePerfConfig — parameter ekonomi global (game_config).
type routePerfConfig struct {
	FuelPrice, CrewCost, TicketBase, TicketKM, MaxWeekly, DemandPoolScale float64
	Demand                                                                demandCurve
	Crew                                                                  crewScale
	BusinessFareMult, FirstFareMult                                       float64
	EconomyWilling, BusinessWilling, FirstWilling                         float64
	CargoPct                                                              float64
}

// routeWeeklyProfit — pure per-route weekly profit estimate for bots. Shares
// routeDailyDemand + allocateCabins with ProcessPlayer (GAME-25). Unlike the
// player tick it excludes event multipliers (bots have no target time) but does
// include cargo revenue and lease cost so the sign matches the player's model.
func routeWeeklyProfit(p routePerfParams, c routePerfConfig) float64 {
	flightHours := p.DistanceKM/p.SpeedKMH + p.TurnaroundHours
	if flightHours <= 0 {
		return 0
	}
	vMaxWeekly := c.MaxWeekly / flightHours
	flights := math.Min(p.FlightsPerWeek, vMaxWeekly)

	econSeats, bizSeats, firstSeats := p.EconomySeats, p.BusinessSeats, p.FirstClassSeats
	if econSeats+bizSeats+firstSeats <= 0 {
		econSeats = int(math.Floor(p.Capacity))
		bizSeats, firstSeats = 0, 0
	}
	dailyDemand := routeDailyDemand(p.OriginDemand, p.DestDemand, p.DistanceKM,
		p.TicketPrice, c.TicketBase, c.TicketKM, c.DemandPoolScale, c.Demand)
	flightsPerDay := flights / 7.0
	allocation := allocateCabins(
		int(math.Round(float64(econSeats)*flightsPerDay)),
		int(math.Round(float64(bizSeats)*flightsPerDay)),
		int(math.Round(float64(firstSeats)*flightsPerDay)),
		p.TicketPrice, c.BusinessFareMult, c.FirstFareMult,
		c.EconomyWilling, c.BusinessWilling, c.FirstWilling,
		dailyDemand, 1.0,
	)
	revenue := allocation.Revenue * 7.0
	revenue += revenue * c.CargoPct
	fuel := flights * p.DistanceKM * p.FuelBurnPerKM * c.FuelPrice
	crew := flights * flightHours * crewCostFor(c.CrewCost, p.Capacity, c.Crew)
	maint := flights * p.DistanceKM * p.MaintCostHr / p.SpeedKMH
	lease := 0.0
	if p.AcqType == "lease" {
		// ProcessPlayer uses lease_price_per_month * (elapsed/30); the weekly
		// run-rate equivalent is the monthly price over ~4.345 weeks.
		lease = p.LeasePriceMonth * 7.0 / 30.0
	}
	return revenue - fuel - crew - maint - lease
}
