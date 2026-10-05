import { services } from '$lib/core/di/services';
import { SyncCoordinator } from '$lib/core/sync/sync-coordinator';
import { SimulationStore } from '$lib/features/simulation/state/simulation-store.svelte';
import { createSimulationGateway } from '$lib/features/simulation/data/create-simulation-gateway';
import { FleetStore } from '$lib/features/fleet/state/fleet-store.svelte';
import { createFleetGateway } from '$lib/features/fleet/data/create-fleet-gateway';
import { RoutesStore } from '$lib/features/routes/state/routes-store.svelte';
import { createRoutesGateway } from '$lib/features/routes/data/create-routes-gateway';
import { BankStore } from '$lib/features/bank/state/bank-store.svelte';
import { createBankGateway } from '$lib/features/bank/data/create-bank-gateway';
import { FinanceStore } from '$lib/features/finance/state/finance-store.svelte';
import { createFinanceGateway } from '$lib/features/finance/data/create-finance-gateway';
import { LeaderboardStore } from '$lib/features/leaderboard/state/leaderboard-store.svelte';
import { createLeaderboardGateway } from '$lib/features/leaderboard/data/create-leaderboard-gateway';
import { AchievementsStore } from '$lib/features/achievements/state/achievements-store.svelte';
import { createAchievementsGateway } from '$lib/features/achievements/data/create-achievements-gateway';
import { EventsStore } from '$lib/features/events/state/events-store.svelte';
import { createEventsGateway } from '$lib/features/events/data/create-events-gateway';
import { SettingsStore } from '$lib/features/settings/state/settings-store.svelte';
import { createSettingsGateway } from '$lib/features/settings/data/create-settings-gateway';
import { NotificationStore } from '$lib/features/notification/state/notification-store.svelte';

/**
 * Kumpulan store per-user (pengganti pusat cubit di `DashboardScreen`).
 *
 * Dibuat sekali setelah auth; ganti user = buat ulang instance ini (keying)
 * sehingga tidak ada state user lama yang bocor ke user baru.
 */
export interface AppStores {
	simulation: SimulationStore;
	fleet: FleetStore;
	routes: RoutesStore;
	bank: BankStore;
	finance: FinanceStore;
	leaderboard: LeaderboardStore;
	achievements: AchievementsStore;
	events: EventsStore;
	settings: SettingsStore;
	notification: NotificationStore;
}

export function createAppStores(): AppStores {
	const sync = new SyncCoordinator();
	return {
		simulation: new SimulationStore({
			gateway: createSimulationGateway(),
			realtime: services.realtimeClient,
			sync
		}),
		fleet: new FleetStore(createFleetGateway()),
		routes: new RoutesStore(createRoutesGateway()),
		bank: new BankStore(createBankGateway()),
		finance: new FinanceStore(createFinanceGateway()),
		leaderboard: new LeaderboardStore(createLeaderboardGateway()),
		achievements: new AchievementsStore(createAchievementsGateway()),
		events: new EventsStore(createEventsGateway()),
		settings: new SettingsStore(createSettingsGateway()),
		notification: new NotificationStore()
	};
}
