/**
 * Konstanta game — fallback klien. Port dari Flutter `GameConstants`.
 *
 * PENTING: sebagian besar nilai di sini hanyalah FALLBACK. Nilai otoritatif
 * datang dari `game_config` (server) lewat `/game-config`. Jangan menganggap
 * konstanta ini sumber kebenaran untuk ekonomi.
 */
export const GameConstants = {
	// Time & clock
	defaultGameSpeedMultiplier: 60.0,
	dbSyncIntervalMs: 60_000,
	settingsCacheTtlMs: 5 * 60_000,

	// Economy fallbacks
	startingCash: 25_000_000.0,
	absoluteMinimumSafetyLimit: 30.0,
	defaultAutoGroundingThreshold: 40.0,

	// Route & fleet
	defaultWeeklyFlights: 7,
	absoluteMaxWeeklyFlights: 168,
	totalWeeklyHoursCap: 168.0,
	aircraftTurnaroundHours: 0.75,
	ownedWearPerFlightCycle: 0.5,
	leasedWearPerFlightCycle: 0.7,

	// Pricing
	ticketBaseFare: 50.0,
	ticketPerKmRate: 0.12,
	fuelPricePerLiter: 0.85,

	// Bankruptcy (fallback)
	bankruptcyCashThreshold: -5_000_000.0,
	bankruptcyNegativeDaysThreshold: 30,

	// Simulation
	maxCondition: 100.0,
	defaultLoanInterestRate: 0.12
} as const;

export const STATUS_ACTIVE = 'Active';
