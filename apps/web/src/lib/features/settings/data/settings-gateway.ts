import { ApiError } from '$lib/core/api/errors';
import type { ApiClient } from '$lib/core/api/api-client';
import type { Airport } from '$lib/features/routes/domain/airport';
import { airportFromMap } from '$lib/features/routes/domain/airport';

export class SettingsGatewayError extends Error {
	readonly operation: string;
	constructor(message: string, operation: string) {
		super(message);
		this.name = 'SettingsGatewayError';
		this.operation = operation;
	}
}

function wrap(err: unknown, operation: string): SettingsGatewayError {
	if (err instanceof ApiError) return new SettingsGatewayError(err.message, operation);
	return new SettingsGatewayError(err instanceof Error ? err.message : String(err), operation);
}

export interface AirlineSettingsInput {
	companyName: string;
	autoGroundingThreshold?: number;
	hqAirportIata?: string;
}

/**
 * Operasi pengaturan via skyward-api (Go REST). Port dari `GoSettingsGateway`.
 *
 * PATCH `/settings` memakai kunci **tanpa prefiks** (`company_name`, …).
 * Server menolak `company_name` kosong, jadi jangan kirim kosong.
 */
export class SettingsGateway {
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

	async saveAirlineSettings(input: AirlineSettingsInput): Promise<void> {
		const body: Record<string, unknown> = { company_name: input.companyName };
		if (input.autoGroundingThreshold !== undefined) {
			body.auto_grounding_threshold = input.autoGroundingThreshold;
		}
		if (input.hqAirportIata !== undefined) body.hq_airport_iata = input.hqAirportIata;
		try {
			await this.api.patch('/settings', body);
		} catch (err) {
			throw wrap(err, 'saveAirlineSettings');
		}
	}

	async resetUserAirline(): Promise<void> {
		try {
			await this.api.post('/settings/reset');
		} catch (err) {
			throw wrap(err, 'resetUserAirline');
		}
	}

	async deleteAccount(): Promise<Record<string, unknown>> {
		try {
			const res = await this.api.delete<Record<string, unknown>>('/account');
			return res ?? { success: true };
		} catch (err) {
			throw wrap(err, 'deleteAccount');
		}
	}

	async loadUserProfile(): Promise<Record<string, unknown>> {
		try {
			return (await this.api.get<Record<string, unknown>>('/simulation/state')) ?? {};
		} catch (err) {
			throw wrap(err, 'loadUserProfile');
		}
	}

	async loadGroundingThreshold(): Promise<number> {
		try {
			const res = await this.api.get<Record<string, unknown>>('/settings/grounding-threshold');
			const v = res?.auto_grounding_threshold;
			return typeof v === 'number' ? v : 40;
		} catch (err) {
			throw wrap(err, 'loadGroundingThreshold');
		}
	}
}
