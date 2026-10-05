import { ApiError } from '$lib/core/api/errors';
import type { ApiClient } from '$lib/core/api/api-client';
import { gameEventFromMap, type GameEvent } from '../domain/game-event';

export class EventsGatewayError extends Error {
	readonly operation: string;
	constructor(message: string, operation: string) {
		super(message);
		this.name = 'EventsGatewayError';
		this.operation = operation;
	}
}

function wrap(err: unknown, operation: string): EventsGatewayError {
	if (err instanceof ApiError) return new EventsGatewayError(err.message, operation);
	return new EventsGatewayError(err instanceof Error ? err.message : String(err), operation);
}

export class EventsGateway {
	constructor(private readonly api: ApiClient) {}

	async loadActiveEvents(): Promise<GameEvent[]> {
		try {
			const res = await this.api.get<unknown>('/events');
			return Array.isArray(res)
				? res
						.filter((m): m is Record<string, unknown> => !!m && typeof m === 'object')
						.map(gameEventFromMap)
				: [];
		} catch (err) {
			throw wrap(err, 'loadActiveEvents');
		}
	}
}
