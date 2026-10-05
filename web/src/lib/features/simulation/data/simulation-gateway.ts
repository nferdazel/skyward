import { ApiError } from '$lib/core/api/errors';
import type { ApiClient } from '$lib/core/api/api-client';

export class SimulationGatewayError extends Error {
	readonly operation: string;
	constructor(message: string, operation: string) {
		super(message);
		this.name = 'SimulationGatewayError';
		this.operation = operation;
	}
}

function wrap(err: unknown, operation: string): SimulationGatewayError {
	if (err instanceof ApiError) return new SimulationGatewayError(err.message, operation);
	return new SimulationGatewayError(err instanceof Error ? err.message : String(err), operation);
}

/**
 * Operasi simulasi via skyward-api (Go REST). Port dari `GoSimulationGateway`.
 *
 * `processSimulationDelta` mengembalikan array (server bisa mengembalikan objek
 * tunggal; dibungkus). `loadUserProfile` mengembalikan peta `{user...}` yang
 * juga memuat `cash`.
 */
export class SimulationGateway {
	constructor(private readonly api: ApiClient) {}

	async processSimulationDelta(): Promise<unknown[]> {
		try {
			const res = await this.api.post<unknown>('/simulation/sync');
			if (Array.isArray(res)) return res;
			if (res && typeof res === 'object') return [res];
			return [];
		} catch (err) {
			throw wrap(err, 'processSimulationDelta');
		}
	}

	async loadUserProfile(): Promise<Record<string, unknown>> {
		try {
			const res = await this.api.get<unknown>('/simulation/state');
			if (res && typeof res === 'object' && !Array.isArray(res)) {
				return res as Record<string, unknown>;
			}
			return {};
		} catch (err) {
			throw wrap(err, 'loadUserProfile');
		}
	}

	async loadGameSettings(): Promise<unknown[]> {
		try {
			const res = await this.api.get<unknown>('/game-config');
			if (Array.isArray(res)) return res;
			if (res && typeof res === 'object') return [res];
			return [];
		} catch (err) {
			throw wrap(err, 'loadGameSettings');
		}
	}

	async getUserBalance(): Promise<number> {
		try {
			const profile = await this.loadUserProfile();
			if (typeof profile.cash === 'number') return profile.cash;
			if (typeof profile.balance === 'number') return profile.balance;
			throw new SimulationGatewayError('balance not present in profile', 'getUserBalance');
		} catch (err) {
			if (err instanceof SimulationGatewayError) throw err;
			throw wrap(err, 'getUserBalance');
		}
	}

	async markOnboardingComplete(): Promise<void> {
		try {
			await this.api.post('/simulation/onboarding');
		} catch (err) {
			throw wrap(err, 'markOnboardingComplete');
		}
	}
}
