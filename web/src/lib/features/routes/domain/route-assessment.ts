/**
 * DTO untuk `GET /routes/assess` dan `/routes/assess/batch`. Bentuknya mengikuti
 * JSON Go apa adanya (snake_case); pemetaan ke tampilan ada di satu tempat.
 *
 * Angka-angka ini berasal dari mesin simulasi yang sama dengan tick, jadi
 * `weekly_*` adalah biaya yang benar-benar dibebankan, bukan perkiraan klien.
 * Port dari Flutter `RouteAssessResultDto` / `RoutePlanAssessmentDto`.
 */
export interface RouteWear {
	perFlightCycle: number;
	grossPerWeek: number;
	selfHealPerWeek: number;
	netPerWeek: number;
	conditionAfterOneWeek: number;
}

export interface RouteViability {
	band: string;
	reasons: string[];
}

export interface RouteMultipliers {
	fuel: number;
	maintenance: number;
	demand: number;
	capacity: number;
}

export interface RouteInputsUsed {
	ticketPrice: number;
	flightsPerWeek: number;
}

export interface RoutePlanAssessment {
	aircraftId: string;
	aircraftModel: string;
	acquisitionType: string;
	flightsPerWeekRequested: number;
	allocatedFlightsPerWeek: number;
	maxWeeklyFlights: number;
	flightDurationHours: number;
	expectedPassengersPerFlight: number;
	seatCapacity: number;
	loadFactorPercent: number;
	directOperatingCostPerFlight: number;
	revenuePerFlight: number;
	contributionPerFlight: number;
	weeklyContribution: number;
	weeklyRevenue: number;
	weeklyCargoRevenue: number;
	weeklyFuelCost: number;
	weeklyCrewCost: number;
	weeklyMaintenanceCost: number;
	weeklyLeaseCost: number;
	wear: RouteWear;
	viability: RouteViability;
	multipliers: RouteMultipliers;
	inputsUsed: RouteInputsUsed;
}

export interface RouteAssessResult {
	routeId: string;
	origin: string;
	destination: string;
	distanceKm: number;
	hasCompatibleAircraft: boolean;
	aircraft: RoutePlanAssessment[];
}

function rec(v: unknown): Record<string, unknown> {
	return v && typeof v === 'object' ? (v as Record<string, unknown>) : {};
}
function str(v: unknown, fallback = ''): string {
	return typeof v === 'string' ? v : fallback;
}
function num(v: unknown, fallback = 0): number {
	return typeof v === 'number' && Number.isFinite(v) ? v : fallback;
}
function arr(v: unknown): unknown[] {
	return Array.isArray(v) ? v : [];
}
function bool(v: unknown): boolean {
	return v === true;
}

function wearFromJson(json: unknown): RouteWear {
	const m = rec(json);
	return {
		perFlightCycle: num(m.per_flight_cycle),
		grossPerWeek: num(m.gross_per_week),
		selfHealPerWeek: num(m.self_heal_per_week),
		netPerWeek: num(m.net_per_week),
		conditionAfterOneWeek: num(m.condition_after_one_week)
	};
}

function viabilityFromJson(json: unknown): RouteViability {
	const m = rec(json);
	return { band: str(m.band), reasons: arr(m.reasons).map((r) => str(r)) };
}

function multipliersFromJson(json: unknown): RouteMultipliers {
	const m = rec(json);
	return {
		fuel: num(m.fuel, 1),
		maintenance: num(m.maintenance, 1),
		demand: num(m.demand, 1),
		capacity: num(m.capacity, 1)
	};
}

function inputsUsedFromJson(json: unknown): RouteInputsUsed {
	const m = rec(json);
	return { ticketPrice: num(m.ticket_price), flightsPerWeek: num(m.flights_per_week) };
}

export function planAssessmentFromJson(json: unknown): RoutePlanAssessment {
	const m = rec(json);
	return {
		aircraftId: str(m.aircraft_id),
		aircraftModel: str(m.aircraft_model),
		acquisitionType: str(m.acquisition_type),
		flightsPerWeekRequested: num(m.flights_per_week_requested),
		allocatedFlightsPerWeek: num(m.allocated_flights_per_week),
		maxWeeklyFlights: num(m.max_weekly_flights),
		flightDurationHours: num(m.flight_duration_hours),
		expectedPassengersPerFlight: num(m.expected_passengers_per_flight),
		seatCapacity: num(m.seat_capacity),
		loadFactorPercent: num(m.load_factor_percent),
		directOperatingCostPerFlight: num(m.direct_operating_cost_per_flight),
		revenuePerFlight: num(m.revenue_per_flight),
		contributionPerFlight: num(m.contribution_per_flight),
		weeklyContribution: num(m.weekly_contribution),
		weeklyRevenue: num(m.weekly_revenue),
		weeklyCargoRevenue: num(m.weekly_cargo_revenue),
		weeklyFuelCost: num(m.weekly_fuel_cost),
		weeklyCrewCost: num(m.weekly_crew_cost),
		weeklyMaintenanceCost: num(m.weekly_maintenance_cost),
		weeklyLeaseCost: num(m.weekly_lease_cost),
		wear: wearFromJson(m.wear),
		viability: viabilityFromJson(m.viability),
		multipliers: multipliersFromJson(m.multipliers),
		inputsUsed: inputsUsedFromJson(m.inputs_used)
	};
}

export function routeAssessResultFromJson(json: unknown): RouteAssessResult {
	const m = rec(json);
	return {
		routeId: str(m.route_id),
		origin: str(m.origin),
		destination: str(m.destination),
		distanceKm: num(m.distance_km),
		hasCompatibleAircraft: bool(m.has_compatible_aircraft),
		aircraft: arr(m.aircraft).map(planAssessmentFromJson)
	};
}

/** Entri dengan kontribusi mingguan tertinggi (pesawat paling menguntungkan). */
export function bestAssessment(result: RouteAssessResult): RoutePlanAssessment | null {
	if (result.aircraft.length === 0) return null;
	return result.aircraft.reduce((a, b) => (b.weeklyContribution > a.weeklyContribution ? b : a));
}
