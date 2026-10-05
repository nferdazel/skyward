import type { EventsGateway } from '../data/events-gateway';
import { isExpired, type GameEvent } from '../domain/game-event';

/** Store event dunia. Port dari `EventsCubit`. Reaktif ke simulation. */
export class EventsStore {
	state = $state<{ loading: boolean; events: GameEvent[]; error: string | null }>({
		loading: false,
		events: [],
		error: null
	});

	constructor(private readonly gateway: EventsGateway) {}

	async load(): Promise<void> {
		this.state = { ...this.state, loading: true, error: null };
		try {
			const events = await this.gateway.loadActiveEvents();
			this.state = { loading: false, events, error: null };
		} catch (err) {
			this.state = {
				...this.state,
				loading: false,
				error: err instanceof Error ? err.message : String(err)
			};
		}
	}

	/** Event yang masih aktif pada waktu tertentu (display-only). */
	activeEvents(nowMs: number): GameEvent[] {
		return this.state.events.filter((e) => e.isActive && !isExpired(e, nowMs));
	}
}
