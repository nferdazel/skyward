import { ApiError } from '$lib/core/api/errors';
import type { ApiClient } from '$lib/core/api/api-client';
import { achievementFromMap, type Achievement } from '../domain/achievement';

export class AchievementsGatewayError extends Error {
	readonly operation: string;
	constructor(message: string, operation: string) {
		super(message);
		this.name = 'AchievementsGatewayError';
		this.operation = operation;
	}
}

function wrap(err: unknown, operation: string): AchievementsGatewayError {
	if (err instanceof ApiError) return new AchievementsGatewayError(err.message, operation);
	return new AchievementsGatewayError(err instanceof Error ? err.message : String(err), operation);
}

export class AchievementsGateway {
	constructor(private readonly api: ApiClient) {}

	async loadAchievements(): Promise<Achievement[]> {
		try {
			const res = await this.api.get<unknown>('/achievements');
			return Array.isArray(res)
				? res
						.filter((m): m is Record<string, unknown> => !!m && typeof m === 'object')
						.map(achievementFromMap)
				: [];
		} catch (err) {
			throw wrap(err, 'loadAchievements');
		}
	}
}
