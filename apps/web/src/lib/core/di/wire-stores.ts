import type { AppStores } from './app-stores.svelte';
import { services } from '$lib/core/di/services';
import { RealtimeSubscription } from '$lib/core/realtime/realtime-subscription';
import { SimulationReactive } from '$lib/core/state/simulation-reactive';

const DEBOUNCE_MS = 400;

interface Debounced {
	(): void;
	cancel(): void;
}

function debounce(fn: () => void, ms: number): Debounced {
	let timer: ReturnType<typeof setTimeout> | null = null;
	const run = () => {
		if (timer !== null) clearTimeout(timer);
		timer = setTimeout(() => {
			timer = null;
			fn();
		}, ms);
	};
	run.cancel = () => {
		if (timer !== null) {
			clearTimeout(timer);
			timer = null;
		}
	};
	return run;
}

/**
 * Sambungkan store satu sama lain (pengganti pola `setupReactivity` di cubit).
 *
 * - Realtime (fleet_aircraft, route_assignments, loans, bank_transactions)
 *   memicu refetch REST — bukan menulis state domain. Dibatasi debounce agar
 *   event beruntun atau reconnect tidak membanjiri API.
 * - Reload setelah sinkronisasi simulasi selesai (transisi true→false) dengan
 *   debounce, agar rentetan tick tidak menghasilkan refetch storm.
 *
 * Mengembalikan fungsi teardown.
 */
export function wireStores(stores: AppStores): () => void {
	const realtime = services.realtimeClient;
	const fleetSub = new RealtimeSubscription(realtime);
	const routesSub = new RealtimeSubscription(realtime);
	const bankSub = new RealtimeSubscription(realtime);
	const reactive = new SimulationReactive(
		() => ({
			isSyncing: stores.simulation.state.isSyncing,
			errorMessage: stores.simulation.state.errorMessage
		}),
		(listener) => stores.simulation.onSyncState(listener)
	);

	const refreshFleet = debounce(() => void stores.fleet.refresh(), DEBOUNCE_MS);
	const refreshRoutes = debounce(() => void stores.routes.refresh(), DEBOUNCE_MS);
	const refreshBank = debounce(() => void stores.bank.refresh(), DEBOUNCE_MS);

	// Realtime refetch.
	fleetSub.subscribe(['fleet_aircraft'], refreshFleet);
	routesSub.subscribe(['route_assignments'], refreshRoutes);
	bankSub.subscribe(['loans', 'bank_transactions'], refreshBank);

	// Reload irisan data saat sinkronisasi simulasi selesai.
	reactive.subscribeToSimulation(() => {
		void stores.fleet.refresh();
		void stores.routes.refresh();
		void stores.bank.refresh();
		void stores.finance.refresh();
		void stores.events.load();
		void stores.achievements.load();
	}, DEBOUNCE_MS);

	// Muat awal.
	void stores.fleet.load();
	void stores.routes.load();
	void stores.bank.load();
	void stores.finance.load();
	void stores.events.load();
	void stores.achievements.load();

	return () => {
		refreshFleet.cancel();
		refreshRoutes.cancel();
		refreshBank.cancel();
		fleetSub.dispose();
		routesSub.dispose();
		bankSub.dispose();
		reactive.dispose();
		stores.simulation.dispose();
	};
}
