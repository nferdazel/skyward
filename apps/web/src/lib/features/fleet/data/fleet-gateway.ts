import { ApiError } from '$lib/core/api/errors';
import type { ApiClient } from '$lib/core/api/api-client';
import {
	aircraftModelFromMap,
	userFleetAircraftFromMap,
	type AircraftModel,
	type UserFleetAircraft
} from '../domain/fleet-models';

export class FleetGatewayError extends Error {
	readonly operation: string;
	constructor(message: string, operation: string) {
		super(message);
		this.name = 'FleetGatewayError';
		this.operation = operation;
	}
}

function wrap(err: unknown, operation: string): FleetGatewayError {
	if (err instanceof ApiError) return new FleetGatewayError(err.message, operation);
	return new FleetGatewayError(err instanceof Error ? err.message : String(err), operation);
}

export interface SeatConfig {
	economySeats: number;
	businessSeats: number;
	firstClassSeats: number;
}

/** Konfigurasi pembelian/sewa. Server memakai nama tanpa prefiks. */
export interface AcquireParams extends SeatConfig {
	modelId: string;
	nickname?: string;
}

/**
 * Operasi armada via skyward-api (Go REST). Port dari `GoFleetGateway`.
 *
 * CATATAN KONTRAK: server Go memakai kunci body **tanpa prefiks**
 * (`model_id`, `economy_seats`, …) dan mengabaikan kunci tak dikenal. Gateway
 * Flutter memetakan `p_*` → unprefixed karena cubit lama mengirim kunci legacy
 * RPC. Di klien baru store mengirim kunci unprefixed langsung; pemetaan itu
 * tidak lagi diperlukan dan tidak dipertahankan.
 */
export class FleetGateway {
	constructor(private readonly api: ApiClient) {}

	async loadFleet(): Promise<UserFleetAircraft[]> {
		try {
			const res = await this.api.get<unknown>('/fleet');
			return Array.isArray(res)
				? res
						.filter((m): m is Record<string, unknown> => !!m && typeof m === 'object')
						.map(userFleetAircraftFromMap)
				: [];
		} catch (err) {
			throw wrap(err, 'loadFleet');
		}
	}

	async loadCatalog(): Promise<AircraftModel[]> {
		try {
			const res = await this.api.get<unknown>('/aircraft-models');
			return Array.isArray(res)
				? res
						.filter((m): m is Record<string, unknown> => !!m && typeof m === 'object')
						.map(aircraftModelFromMap)
				: [];
		} catch (err) {
			throw wrap(err, 'loadCatalog');
		}
	}

	private acquireBody(params: AcquireParams): Record<string, unknown> {
		return {
			model_id: params.modelId,
			nickname: params.nickname ?? '',
			economy_seats: params.economySeats,
			business_seats: params.businessSeats,
			first_class_seats: params.firstClassSeats
		};
	}

	async purchaseAircraft(params: AcquireParams): Promise<void> {
		try {
			await this.api.post('/fleet/purchase', this.acquireBody(params));
		} catch (err) {
			throw wrap(err, 'purchaseAircraft');
		}
	}

	async leaseAircraft(params: AcquireParams): Promise<void> {
		try {
			await this.api.post('/fleet/lease', this.acquireBody(params));
		} catch (err) {
			throw wrap(err, 'leaseAircraft');
		}
	}

	async repairAircraft(aircraftId: string): Promise<void> {
		try {
			await this.api.post(`/fleet/${aircraftId}/repair`);
		} catch (err) {
			throw wrap(err, 'repairAircraft');
		}
	}

	async sellAircraft(aircraftId: string): Promise<void> {
		try {
			await this.api.post(`/fleet/${aircraftId}/sell`);
		} catch (err) {
			throw wrap(err, 'sellAircraft');
		}
	}

	async terminateLease(aircraftId: string): Promise<void> {
		try {
			await this.api.post(`/fleet/${aircraftId}/terminate-lease`);
		} catch (err) {
			throw wrap(err, 'terminateLease');
		}
	}

	async configureSeats(aircraftId: string, seats: SeatConfig): Promise<void> {
		try {
			await this.api.patch(`/fleet/${aircraftId}/seats`, {
				economy_seats: seats.economySeats,
				business_seats: seats.businessSeats,
				first_class_seats: seats.firstClassSeats
			});
		} catch (err) {
			throw wrap(err, 'configureSeats');
		}
	}

	async fetchLatestAircraftForModel(modelId: string): Promise<UserFleetAircraft | null> {
		try {
			const res = await this.api.get<unknown>(`/fleet/models/${modelId}/latest`);
			const row = Array.isArray(res) ? res[0] : res;
			return row && typeof row === 'object'
				? userFleetAircraftFromMap(row as Record<string, unknown>)
				: null;
		} catch (err) {
			throw wrap(err, 'fetchLatestAircraftForModel');
		}
	}

	async fetchSingleAircraft(aircraftId: string): Promise<UserFleetAircraft | null> {
		try {
			const res = await this.api.get<unknown>(`/fleet/${aircraftId}`);
			return res && typeof res === 'object'
				? userFleetAircraftFromMap(res as Record<string, unknown>)
				: null;
		} catch (err) {
			throw wrap(err, 'fetchSingleAircraft');
		}
	}
}
