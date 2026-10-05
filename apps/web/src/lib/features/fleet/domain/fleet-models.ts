import { GameConstants } from '$lib/core/constants/game-constants';

/** Model pesawat dari katalog. Port dari Flutter `AircraftModel`. */
export interface AircraftModel {
	id: string;
	manufacturer: string;
	modelName: string;
	type: string;
	rangeKm: number;
	capacity: number;
	speedKmh: number;
	fuelBurnPerKm: number;
	maintenanceCostPerHour: number;
	purchasePrice: number;
	leasePricePerMonth: number;
	/** AVIATION-13: jam turnaround otoritatif dari `aircraft_models`. */
	turnaroundHours: number;
	/** GAME-06: tier kredit minimum untuk beli/sewa model ini. */
	minCreditTier: string;
}

function str(v: unknown, fallback = ''): string {
	return typeof v === 'string' ? v : fallback;
}
function num(v: unknown, fallback = 0): number {
	return typeof v === 'number' && Number.isFinite(v) ? v : fallback;
}

export function aircraftModelFromMap(map: Record<string, unknown>): AircraftModel {
	return {
		id: str(map.id),
		manufacturer: str(map.manufacturer),
		modelName: str(map.model_name),
		type: str(map.type),
		rangeKm: num(map.range_km),
		capacity: num(map.capacity),
		speedKmh: num(map.speed_kmh, 850),
		fuelBurnPerKm: num(map.fuel_burn_per_km),
		maintenanceCostPerHour: num(map.maintenance_cost_per_hour),
		purchasePrice: num(map.purchase_price),
		leasePricePerMonth: num(map.lease_price_per_month),
		turnaroundHours: num(map.turnaround_hours, GameConstants.aircraftTurnaroundHours),
		minCreditTier: str(map.min_credit_tier, 'Standard')
	};
}

/**
 * Pesawat milik pemain. Port dari Flutter `UserFleetAircraft`.
 *
 * `saleValue`, `repairCost`, `leaseExitFee` datang dari SERVER — klien tidak
 * menghitungnya. Sebelumnya `estimatedSaleValue` dihitung klien (`purchasePrice
 * * 0.72`) sementara server memakai depresiasi umur, jadi angka yang dilihat
 * pemain bisa berbeda dari yang diterima, tanpa error.
 */
export interface UserFleetAircraft {
	id: string;
	nickname: string;
	acquisitionType: string;
	condition: number;
	status: string;
	model: AircraftModel;
	economySeats: number;
	businessSeats: number;
	firstClassSeats: number;
	tailNumber: string;
	saleValue: number;
	repairCost: number;
	leaseExitFee: number;
	canBeSold: boolean;
	saleValueNote: string | null;
}

export function userFleetAircraftFromMap(map: Record<string, unknown>): UserFleetAircraft {
	let modelMap: Record<string, unknown>;
	if (map.aircraft_models && typeof map.aircraft_models === 'object') {
		modelMap = map.aircraft_models as Record<string, unknown>;
	} else {
		modelMap = {
			id: map.aircraft_model_id ?? map.model_id ?? '',
			model_name: map.model_name ?? '',
			manufacturer: map.manufacturer ?? '',
			type: map.type ?? '',
			range_km: map.range_km ?? 0,
			capacity: map.capacity ?? 0,
			speed_kmh: map.speed_kmh ?? 850,
			fuel_burn_per_km: map.fuel_burn_per_km ?? 0,
			maintenance_cost_per_hour: map.maintenance_cost_per_hour ?? 0,
			purchase_price: map.purchase_price ?? 0,
			lease_price_per_month: map.lease_price_per_month ?? 0,
			turnaround_hours: map.turnaround_hours,
			min_credit_tier: map.min_credit_tier
		};
	}
	return {
		id: str(map.id),
		nickname: str(map.nickname),
		acquisitionType: str(map.acquisition_type, 'purchase'),
		condition: num(map.condition, 100),
		status: str(map.status, 'active'),
		model: aircraftModelFromMap(modelMap),
		economySeats: num(map.economy_seats),
		businessSeats: num(map.business_seats),
		firstClassSeats: num(map.first_class_seats),
		tailNumber: str(map.tail_number),
		saleValue: num(map.sale_value),
		repairCost: num(map.repair_cost),
		leaseExitFee: num(map.lease_exit_fee),
		canBeSold: map.can_be_sold === true,
		saleValueNote: typeof map.sale_value_note === 'string' ? map.sale_value_note : null
	};
}

// ── Helper domain (fungsi murni; tidak menghitung ekonomi otoritatif) ─────────

export function isOwned(a: UserFleetAircraft): boolean {
	return a.acquisitionType === 'purchase';
}

export function maintenanceWearPerFlightCycle(a: UserFleetAircraft): number {
	return a.acquisitionType === 'lease'
		? GameConstants.leasedWearPerFlightCycle
		: GameConstants.ownedWearPerFlightCycle;
}

export function isMaintenanceGrounded(
	a: UserFleetAircraft,
	autoGroundingThreshold: number
): boolean {
	const effective =
		autoGroundingThreshold > GameConstants.absoluteMinimumSafetyLimit
			? autoGroundingThreshold
			: GameConstants.absoluteMinimumSafetyLimit;
	return a.status === 'grounded' || a.condition < effective;
}

export function effectivePassengerCapacity(a: UserFleetAircraft): number {
	const configured = a.economySeats + a.businessSeats + a.firstClassSeats;
	return configured > 0 ? configured : a.model.capacity;
}

export function canOperateDistance(a: UserFleetAircraft, distanceKm: number): boolean {
	return a.model.rangeKm >= Math.ceil(distanceKm);
}
