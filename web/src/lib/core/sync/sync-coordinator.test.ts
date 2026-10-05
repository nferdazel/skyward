import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { fleetUpdated, routeUpdated, seasonClockTick } from './domain-events';
import { SyncCoordinator } from './sync-coordinator';

describe('SyncCoordinator', () => {
	beforeEach(() => vi.useFakeTimers());
	afterEach(() => vi.useRealTimers());

	it('delivers events only to listeners of the same kind', () => {
		const sync = new SyncCoordinator();
		const fleet: string[] = [];
		const route: string[] = [];
		sync.listen('fleet_updated', (e) => fleet.push(e.action ?? ''));
		sync.listen('route_updated', (e) => route.push(e.action ?? ''));

		sync.publish(fleetUpdated({ action: 'buy' }));
		sync.publish(routeUpdated({ action: 'assign' }));

		expect(fleet).toEqual(['buy']);
		expect(route).toEqual(['assign']);
	});

	it('debounces trailing-edge: rapid events collapse to the last one', () => {
		const sync = new SyncCoordinator();
		const seen: number[] = [];
		sync.listen('season_clock_tick', (e) => seen.push(e.currentTick ?? -1), { debounceMs: 200 });

		sync.publish(seasonClockTick({ currentTick: 1 }));
		sync.publish(seasonClockTick({ currentTick: 2 }));
		sync.publish(seasonClockTick({ currentTick: 3 }));
		expect(seen).toEqual([]);

		vi.advanceTimersByTime(200);
		expect(seen).toEqual([3]);
	});

	it('cancels a pending debounce when the listener unsubscribes', () => {
		const sync = new SyncCoordinator();
		const seen: number[] = [];
		const off = sync.listen('season_clock_tick', (e) => seen.push(e.currentTick ?? -1), {
			debounceMs: 200
		});

		sync.publish(seasonClockTick({ currentTick: 7 }));
		off();
		vi.advanceTimersByTime(500);

		expect(seen).toEqual([]);
	});

	it('stops delivering after unsubscribe', () => {
		const sync = new SyncCoordinator();
		let count = 0;
		const off = sync.listen('fleet_updated', () => (count += 1));

		sync.publish(fleetUpdated({ action: 'a' }));
		off();
		sync.publish(fleetUpdated({ action: 'b' }));

		expect(count).toBe(1);
	});
});
