import { afterEach, describe, expect, it, vi } from 'vitest';
import { SimulationStore, flattenGameConfig } from './simulation-store.svelte';
import { SyncCoordinator } from '$lib/core/sync/sync-coordinator';
import type { SimulationGateway } from '../data/simulation-gateway';
import type { RealtimeClient } from '$lib/core/realtime/realtime-client';

function makeGateway(overrides: Partial<SimulationGateway> = {}): SimulationGateway {
	return {
		processSimulationDelta: vi.fn().mockResolvedValue([]),
		loadUserProfile: vi.fn().mockResolvedValue({}),
		loadGameSettings: vi.fn().mockResolvedValue([]),
		getUserBalance: vi.fn().mockResolvedValue(0),
		markOnboardingComplete: vi.fn().mockResolvedValue(undefined),
		...overrides
	} as unknown as SimulationGateway;
}

const realtime = {
	connect: vi.fn(async () => {}),
	subscribe: vi.fn(),
	unsubscribe: vi.fn(),
	onEvent: vi.fn(() => () => {})
} as unknown as RealtimeClient;

describe('flattenGameConfig', () => {
	it('flattens {key,value} entries and coerces numeric strings', () => {
		const flat = flattenGameConfig([
			{ key: 'fuel_price_per_liter', value: '0.9', category: 'x' },
			{ key: 'time_scale_multiplier', value: 120 },
			{ key: 'label', value: 'hello' }
		]);
		expect(flat).toEqual({
			fuel_price_per_liter: 0.9,
			time_scale_multiplier: 120,
			label: 'hello'
		});
	});

	it('merges a flat settings map, skipping metadata keys', () => {
		const flat = flattenGameConfig([{ ticket_base_fare: '60', category: 'pricing', unit: 'idr' }]);
		expect(flat).toEqual({ ticket_base_fare: 60 });
	});
});

describe('SimulationStore', () => {
	afterEach(() => vi.useRealTimers());

	it('sync updates state from the profile and delta, and publishes a tick event', async () => {
		const gateway = makeGateway({
			processSimulationDelta: vi
				.fn()
				.mockResolvedValue([
					{ elapsed_game_days: 1.5, flights_run: 4, revenue: 1000, expense: 400 }
				]),
			loadUserProfile: vi.fn().mockResolvedValue({
				id: 'u1',
				username: 'fredi',
				cash: 5000,
				game_current_time: '2030-02-01T00:00:00Z',
				operational_status: 'Active'
			}),
			loadGameSettings: vi.fn().mockResolvedValue([
				{ key: 'fuel_price_per_liter', value: 0.9 },
				{ key: 'ticket_base_fare', value: 60 }
			])
		});
		const sync = new SyncCoordinator();
		const published: number[] = [];
		sync.listen('season_clock_tick', (e) => published.push(e.currentTick ?? 0));

		const store = new SimulationStore({ gateway, realtime, sync });
		store.beginSession({ userId: 'u1', initialGameTime: '2030-01-01T00:00:00Z', initialCash: 0 });

		await store.syncWithDatabase();

		expect(store.state.cashBalance).toBe(5000);
		expect(store.state.lastFlightsRun).toBe(4);
		expect(store.state.fuelPricePerLiter).toBe(0.9);
		expect(store.state.ticketBaseFare).toBe(60);
		expect(store.state.isSyncing).toBe(false);
		expect(published).toHaveLength(1);

		store.dispose();
	});

	it('does not overwrite state when the user changed mid-flight', async () => {
		let resolveProfile: (v: Record<string, unknown>) => void = () => {};
		const profilePromise = new Promise<Record<string, unknown>>((r) => (resolveProfile = r));
		const gateway = makeGateway({
			loadUserProfile: vi.fn().mockReturnValue(profilePromise)
		});
		const store = new SimulationStore({ gateway, realtime, sync: new SyncCoordinator() });
		store.beginSession({ userId: 'u1', initialGameTime: '2030-01-01T00:00:00Z', initialCash: 0 });

		const pending = store.syncWithDatabase();
		// Ganti user selagi sync in-flight.
		store.beginSession({ userId: 'u2', initialGameTime: '2031-01-01T00:00:00Z', initialCash: 0 });
		resolveProfile({ id: 'u1', cash: 9999 });

		const result = await pending;
		expect(result).toBeNull();
		store.dispose();
	});

	it('baseTicketPrice uses server config values', () => {
		const store = new SimulationStore({
			gateway: makeGateway(),
			realtime,
			sync: new SyncCoordinator()
		});
		store.state = { ...store.state, ticketBaseFare: 50, ticketPerKmRate: 0.1 };
		expect(store.baseTicketPrice(1000)).toBeCloseTo(150);
	});

	it('caches game settings within the TTL', async () => {
		const loadGameSettings = vi
			.fn()
			.mockResolvedValue([{ key: 'fuel_price_per_liter', value: 1.2 }]);
		const gateway = makeGateway({
			loadGameSettings,
			loadUserProfile: vi
				.fn()
				.mockResolvedValue({ id: 'u1', game_current_time: '2030-01-01T00:00:00Z' })
		});
		let clock = 0;
		const store = new SimulationStore({
			gateway,
			realtime,
			sync: new SyncCoordinator(),
			now: () => clock
		});
		store.beginSession({ userId: 'u1', initialGameTime: '2030-01-01T00:00:00Z', initialCash: 0 });

		await store.syncWithDatabase();
		clock += 1000; // dalam TTL
		await store.syncWithDatabase();

		expect(loadGameSettings).toHaveBeenCalledTimes(1);
		store.dispose();
	});

	it('notifies sync-state listeners across a sync cycle', async () => {
		const gateway = makeGateway({
			loadUserProfile: vi
				.fn()
				.mockResolvedValue({ id: 'u1', game_current_time: '2030-01-01T00:00:00Z' })
		});
		const store = new SimulationStore({ gateway, realtime, sync: new SyncCoordinator() });
		store.beginSession({ userId: 'u1', initialGameTime: '2030-01-01T00:00:00Z', initialCash: 0 });

		const seen: boolean[] = [];
		const off = store.onSyncState((s) => seen.push(s.isSyncing));

		await store.syncWithDatabase();

		expect(seen).toEqual([true, false]);
		off();
		store.dispose();
	});
});
