import { ApiError } from '$lib/core/api/errors';
import type { ApiClient } from '$lib/core/api/api-client';
import {
	competitorInsightsFromMap,
	leaderboardEntryFromMap,
	type CompetitorInsights,
	type LeaderboardEntry
} from '../domain/leaderboard-models';

export class LeaderboardGatewayError extends Error {
	readonly operation: string;
	constructor(message: string, operation: string) {
		super(message);
		this.name = 'LeaderboardGatewayError';
		this.operation = operation;
	}
}

function wrap(err: unknown, operation: string): LeaderboardGatewayError {
	if (err instanceof ApiError) return new LeaderboardGatewayError(err.message, operation);
	return new LeaderboardGatewayError(err instanceof Error ? err.message : String(err), operation);
}

export class LeaderboardGateway {
	constructor(private readonly api: ApiClient) {}

	async getGlobalLeaderboard(): Promise<LeaderboardEntry[]> {
		try {
			const res = await this.api.get<unknown>('/leaderboard');
			return Array.isArray(res)
				? res
						.filter((m): m is Record<string, unknown> => !!m && typeof m === 'object')
						.map(leaderboardEntryFromMap)
				: [];
		} catch (err) {
			throw wrap(err, 'getGlobalLeaderboard');
		}
	}

	async getCompetitorInsights(id: string, isBot: boolean): Promise<CompetitorInsights[]> {
		try {
			const res = await this.api.get<unknown>(`/leaderboard/competitors/${id}`, { isBot });
			const list = Array.isArray(res) ? res : res && typeof res === 'object' ? [res] : [];
			return list
				.filter((m): m is Record<string, unknown> => !!m && typeof m === 'object')
				.map(competitorInsightsFromMap);
		} catch (err) {
			throw wrap(err, 'getCompetitorInsights');
		}
	}
}
