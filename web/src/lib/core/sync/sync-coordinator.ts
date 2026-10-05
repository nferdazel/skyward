import type {
	AppDomainEvent,
	BankTransactionEvent,
	FleetUpdatedEvent,
	RouteUpdatedEvent,
	SeasonClockTickEvent
} from './domain-events';

export type EventListener<T extends AppDomainEvent> = (event: T) => void;

export interface Unsubscribe {
	(): void;
}

/** Pemetaan kind → tipe event, agar `listen` meng-infer tipe callback dengan benar. */
export interface DomainEventMap {
	fleet_updated: FleetUpdatedEvent;
	route_updated: RouteUpdatedEvent;
	bank_transaction: BankTransactionEvent;
	season_clock_tick: SeasonClockTickEvent;
}

export type DomainEventKind = keyof DomainEventMap;

export interface TimerApi {
	setTimeout(fn: () => void, ms: number): unknown;
	clearTimeout(handle: unknown): void;
}

const defaultTimers: TimerApi = {
	setTimeout: (fn, ms) => setTimeout(fn, ms),
	clearTimeout: (h) => clearTimeout(h as ReturnType<typeof setTimeout>)
};

/**
 * Event bus internal + koordinator sinkronisasi. Port dari Flutter
 * `SyncCoordinator`.
 *
 * Menghubungkan store, listener realtime, dan worker tanpa referensi silang.
 * Mendukung debounce trailing-edge: event beruntun menggeser callback; membatalkan
 * listener juga membatalkan timer debounce yang tertunda (AUDIT-18).
 */
export class SyncCoordinator {
	private readonly listeners = new Map<string, Set<EventListener<AppDomainEvent>>>();

	constructor(private readonly timers: TimerApi = defaultTimers) {}

	publish(event: AppDomainEvent): void {
		const set = this.listeners.get(event.kind);
		if (!set) return;
		for (const listener of set) listener(event);
	}

	/** Daftarkan listener untuk satu jenis event. Mengembalikan pembatal. */
	listen<K extends DomainEventKind>(
		kind: K,
		onData: (event: DomainEventMap[K]) => void,
		opts?: { debounceMs?: number }
	): Unsubscribe {
		const debounceMs = opts?.debounceMs ?? 0;
		let timer: unknown = null;
		let last: DomainEventMap[K] | null = null;

		const wrapped: EventListener<AppDomainEvent> = (event) => {
			if (debounceMs <= 0) {
				onData(event as DomainEventMap[K]);
				return;
			}
			last = event as DomainEventMap[K];
			if (timer !== null) this.timers.clearTimeout(timer);
			timer = this.timers.setTimeout(() => {
				timer = null;
				if (last !== null) {
					onData(last);
					last = null;
				}
			}, debounceMs);
		};

		let set = this.listeners.get(kind);
		if (!set) {
			set = new Set();
			this.listeners.set(kind, set);
		}
		set.add(wrapped);

		return () => {
			set?.delete(wrapped);
			if (timer !== null) {
				this.timers.clearTimeout(timer);
				timer = null;
			}
			last = null;
		};
	}

	/** Bersihkan semua listener (dipakai saat teardown/test). */
	dispose(): void {
		this.listeners.clear();
	}
}
