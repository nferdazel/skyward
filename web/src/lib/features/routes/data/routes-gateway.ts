import { ApiError } from '$lib/core/api/errors';
import type { ApiClient } from '$lib/core/api/api-client';
import { airportFromMap, type Airport } from '../domain/airport';
import {
	bestAssessment,
	routeAssessResultFromJson,
	type RoutePlanAssessment
} from '../domain/route-assessment';
import { userRouteFromMap, type UserRoute } from '../domain/route-models';
import type { UserFleetAircraft } from '$lib/features/fleet/domain/fleet-models';
import { userFleetAircraftFromMap } from '$lib/features/fleet/domain/fleet-models';

export class RoutesGatewayError extends Error {
	readonly operation: string;
	constructor(message: string, operation: string) {
		super(message);
		this.name = 'RoutesGatewayError';
		this.operation = operation;
	}
}

function wrap(err: unknown, operation: string): RoutesGatewayError {
	if (err instanceof ApiError) return new RoutesGatewayError(err.message, operation);
	return new RoutesGatewayError(err instanceof Error ? err.message : String(err), operation);
}

export interface AssessParams {
	originIata: string;
	destinationIata: string;
	ticketPrice: number;
	flightsPerWeek: number;
	aircraftId?: string;
}

/**
 * Operasi rute via skyward-api (Go REST). Port dari `GoRoutesGateway`.
 *
 * Validasi per 2026-10-05: `assignAircraft` menerima string kosong sebagai
 * PELEPASAN pesawat (lihat decisions.md bug 5) — jangan kirim null.
 */
export class RoutesGateway {
	constructor(private readonly api: ApiClient) {}

	async loadAirports(): Promise<Airport[]> {
		try {
			const res = await this.api.get<unknown>('/airports');
			return Array.isArray(res)
				? res
						.filter((m): m is Record<string, unknown> => !!m && typeof m === 'object')
						.map(airportFromMap)
				: [];
		} catch (err) {
			throw wrap(err, 'loadAirports');
		}
	}

	async loadRoutes(): Promise<UserRoute[]> {
		try {
			const res = await this.api.get<unknown>('/routes');
			return Array.isArray(res)
				? res
						.filter((m): m is Record<string, unknown> => !!m && typeof m === 'object')
						.map(userRouteFromMap)
				: [];
		} catch (err) {
			throw wrap(err, 'loadRoutes');
		}
	}

	async loadGroundingThreshold(): Promise<number> {
		try {
			const res = await this.api.get<Record<string, unknown>>('/settings/grounding-threshold');
			const value = res?.auto_grounding_threshold;
			return typeof value === 'number' ? value : 40;
		} catch (err) {
			throw wrap(err, 'loadGroundingThreshold');
		}
	}

	async loadAvailableFleet(): Promise<UserFleetAircraft[]> {
		try {
			const res = await this.api.get<unknown>('/fleet/available');
			return Array.isArray(res)
				? res
						.filter((m): m is Record<string, unknown> => !!m && typeof m === 'object')
						.map(userFleetAircraftFromMap)
				: [];
		} catch (err) {
			throw wrap(err, 'loadAvailableFleet');
		}
	}

	async createRoute(input: {
		originIata: string;
		destinationIata: string;
		distanceKm: number;
		ticketPrice: number;
		flightsPerWeek: number;
	}): Promise<void> {
		try {
			await this.api.post('/routes', {
				origin_iata: input.originIata,
				destination_iata: input.destinationIata,
				distance_km: input.distanceKm,
				ticket_price: input.ticketPrice,
				flights_per_week: input.flightsPerWeek
			});
		} catch (err) {
			throw wrap(err, 'createRoute');
		}
	}

	/** `aircraftId` null = lepas pesawat (server menerima string kosong). */
	async assignAircraft(routeId: string, aircraftId: string | null): Promise<void> {
		try {
			await this.api.post(`/routes/${routeId}/assign`, { aircraft_id: aircraftId ?? '' });
		} catch (err) {
			throw wrap(err, 'assignAircraft');
		}
	}

	async updateRoute(routeId: string, ticketPrice: number, flightsPerWeek: number): Promise<void> {
		try {
			await this.api.patch(`/routes/${routeId}`, {
				ticket_price: ticketPrice,
				flights_per_week: flightsPerWeek
			});
		} catch (err) {
			throw wrap(err, 'updateRoute');
		}
	}

	async deleteRoute(routeId: string): Promise<void> {
		try {
			await this.api.delete(`/routes/${routeId}`);
		} catch (err) {
			throw wrap(err, 'deleteRoute');
		}
	}

	/** Peta `routeId → penilaian terbaik` dari `/routes/assess/batch`. */
	async loadRouteAssessments(): Promise<Record<string, RoutePlanAssessment>> {
		try {
			const res = await this.api.get<unknown>('/routes/assess/batch');
			const routes = (
				res && typeof res === 'object' && 'routes' in res
					? (res as Record<string, unknown>).routes
					: []
			) as unknown;
			const out: Record<string, RoutePlanAssessment> = {};
			if (Array.isArray(routes)) {
				for (const raw of routes) {
					const dto = routeAssessResultFromJson(raw);
					const best = bestAssessment(dto);
					if (!dto.routeId || !best) continue;
					out[dto.routeId] = best;
				}
			}
			return out;
		} catch (err) {
			throw wrap(err, 'loadRouteAssessments');
		}
	}

	async assessRoute(params: AssessParams): Promise<RoutePlanAssessment | null> {
		try {
			const res = await this.api.get<unknown>('/routes/assess', {
				origin_iata: params.originIata,
				destination_iata: params.destinationIata,
				ticket_price: params.ticketPrice,
				flights_per_week: params.flightsPerWeek,
				aircraft_id: params.aircraftId
			});
			return bestAssessment(routeAssessResultFromJson(res));
		} catch (err) {
			throw wrap(err, 'assessRoute');
		}
	}
}
