import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { SimulationReactive, type SyncState } from './simulation-reactive';

describe('SimulationReactive', () => {
	beforeEach(() => vi.useFakeTimers());
	afterEach(() => vi.useRealTimers());

	function makeHarness() {
		const listeners = new Set<(s: SyncState) => void>();
		let state: SyncState = { isSyncing: false, errorMessage: null };
		const reactive = new SimulationReactive(
			() => state,
			(listener) => {
				listeners.add(listener);
				return () => listeners.delete(listener);
			}
		);
		const emit = (patch: Partial<SyncState>) => {
			state = { ...state, ...patch };
			for (const l of listeners) l(state);
		};
		return { reactive, emit };
	}

	it('fires on the true→false transition without error', () => {
		const { reactive, emit } = makeHarness();
		const done = vi.fn();
		reactive.subscribeToSimulation(done);

		emit({ isSyncing: true });
		emit({ isSyncing: false });
		expect(done).toHaveBeenCalledOnce();
	});

	it('does not fire when the sync ended with an error', () => {
		const { reactive, emit } = makeHarness();
		const done = vi.fn();
		reactive.subscribeToSimulation(done);

		emit({ isSyncing: true, errorMessage: 'boom' });
		emit({ isSyncing: false, errorMessage: 'boom' });
		expect(done).not.toHaveBeenCalled();
	});

	it('debounces trailing-edge and a new sync cancels the pending callback', () => {
		const { reactive, emit } = makeHarness();
		const done = vi.fn();
		reactive.subscribeToSimulation(done, 200);

		emit({ isSyncing: true });
		emit({ isSyncing: false });
		emit({ isSyncing: true });
		emit({ isSyncing: false });

		vi.advanceTimersByTime(200);
		expect(done).toHaveBeenCalledOnce();
	});

	it('cancels a pending callback on dispose', () => {
		const { reactive, emit } = makeHarness();
		const done = vi.fn();
		reactive.subscribeToSimulation(done, 200);

		emit({ isSyncing: true });
		emit({ isSyncing: false });
		reactive.dispose();
		vi.advanceTimersByTime(500);

		expect(done).not.toHaveBeenCalled();
	});
});
