import {
	userFleetAircraftFromMap,
	effectivePassengerCapacity,
	canOperateDistance,
	type UserFleetAircraft
} from '$lib/features/fleet/domain/fleet-models';
import { airportFromMap, type Airport } from './airport';

/**
 * Rute milik pemain. Port dari Flutter `UserRoute`.
 *
 * File ini TIDAK menghitung ekonomi rute. Hanya geometri & tampilan: jarak
 * bandara, durasi penerbangan, ASK. Harga tiket dasar, batas frekuensi, dan
 * keausan datang dari server.
 */
export interface UserRoute {
	id: string;
	originIata: string;
	destinationIata: string;
	distanceKm: number;
	ticketPrice: number;
	assignedAircraftId: string | null;
	flightsPerWeek: number;
	origin: Airport;
	destination: Airport;
	assignedAircraft: UserFleetAircraft | null;
	status: string;
}

function str(v: unknown, fallback = ''): string {
	return typeof v === 'string' ? v : fallback;
}
function num(v: unknown, fallback = 0): number {
	return typeof v === 'number' && Number.isFinite(v) ? v : fallback;
}
function rec(v: unknown): Record<string, unknown> | null {
	return v && typeof v === 'object' ? (v as Record<string, unknown>) : null;
}

export function userRouteFromMap(map: Record<string, unknown>): UserRoute {
	const originMap = rec(map.origin) ?? { iata: map.origin_iata };
	const destMap = rec(map.destination) ?? { iata: map.destination_iata };

	let assigned: UserFleetAircraft | null = null;
	const fleet = rec(map.fleet_aircraft);
	if (fleet) {
		assigned = userFleetAircraftFromMap(fleet);
	} else if (map.tail_number != null) {
		// AUDIT-15: server mengirim atribut pesawat ter-assign; stub ber-capacity-0
		// akan merusak load factor & preview.
		assigned = userFleetAircraftFromMap({
			id: map.assigned_aircraft_id,
			tail_number: map.tail_number,
			model_name: map.model_name,
			capacity: map.assigned_capacity,
			range_km: map.assigned_range_km,
			speed_kmh: map.assigned_speed_kmh,
			fuel_burn_per_km: map.assigned_fuel_burn_per_km,
			maintenance_cost_per_hour: map.assigned_maintenance_cost_per_hour,
			condition: map.assigned_condition
		});
	}

	return {
		id: str(map.id),
		originIata: str(map.origin_iata),
		destinationIata: str(map.destination_iata),
		distanceKm: num(map.distance_km),
		ticketPrice: num(map.ticket_price),
		assignedAircraftId:
			typeof map.assigned_aircraft_id === 'string' ? map.assigned_aircraft_id : null,
		flightsPerWeek: num(map.flights_per_week, 7),
		origin: airportFromMap(originMap),
		destination: airportFromMap(destMap),
		assignedAircraft: assigned,
		status: str(map.status, 'active')
	};
}

/** Available Seat Kilometers (ASK) per minggu. 0 bila tak ada pesawat cocok. */
export function weeklyASK(route: UserRoute): number {
	const aircraft = route.assignedAircraft;
	if (!aircraft || !canOperateDistance(aircraft, route.distanceKm)) return 0;
	return effectivePassengerCapacity(aircraft) * route.distanceKm * route.flightsPerWeek;
}

/** Durasi satu siklus penerbangan (jam), termasuk turnaround model. */
export function flightDurationHours(route: UserRoute): number {
	const aircraft = route.assignedAircraft;
	if (!aircraft) return 0;
	return route.distanceKm / aircraft.model.speedKmh + aircraft.model.turnaroundHours;
}
