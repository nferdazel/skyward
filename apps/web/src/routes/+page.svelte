<script lang="ts">
	import AppSidebar from '$lib/core/components/AppSidebar.svelte';
	import type { NavKey } from '$lib/core/components/nav';
	import TopHud from '$lib/core/components/TopHud.svelte';
	import SkywardSonner from '$lib/core/components/SkywardSonner.svelte';
	import OverviewTab from '$lib/features/dashboard/ui/OverviewTab.svelte';
	import FleetView from '$lib/features/fleet/ui/FleetView.svelte';
	import RoutesView from '$lib/features/routes/ui/RoutesView.svelte';
	import BankView from '$lib/features/bank/ui/BankView.svelte';
	import FinanceView from '$lib/features/finance/ui/FinanceView.svelte';
	import LeaderboardView from '$lib/features/leaderboard/ui/LeaderboardView.svelte';
	import SettingsView from '$lib/features/settings/ui/SettingsView.svelte';
	import { getAuthStore } from '$lib/features/auth/state/auth-context.svelte';
	import { appStores } from '$lib/core/di/stores-context.svelte';

	const auth = getAuthStore();
	// The layout renders this page only once stores are ready.
	const stores = $derived(appStores.stores!);

	let tab = $state<NavKey>('dashboard');

	// Leaderboard loads lazily on first open.
	$effect(() => {
		if (tab === 'rankings' && stores.leaderboard.state.entries.length === 0) {
			void stores.leaderboard.load();
		}
	});

	// New achievements from sync become toasts (once each).
	const seenAchievements = new Set<string>();
	$effect(() => {
		for (const a of stores.simulation.state.lastUnlockedAchievements) {
			const key = String(a.achievement_type ?? a.achievement_name ?? '');
			if (!key || seenAchievements.has(key)) continue;
			seenAchievements.add(key);
			stores.notification.push({
				type: 'success',
				title: String(a.achievement_name ?? 'Achievement'),
				message: String(a.description ?? '')
			});
		}
	});
</script>

<svelte:head><title>Skyward — Command Center</title></svelte:head>

<div class="app">
	<AppSidebar active={tab} onselect={(k) => (tab = k)} onlogout={() => auth.logout()} />

	<div class="main">
		{#if auth.user}
			<TopHud user={auth.user} sim={stores.simulation.state} />
		{/if}

		<div class="content">
			{#if tab === 'dashboard'}
				{#if auth.user}
					<OverviewTab {stores} user={auth.user} onnavigate={(t) => (tab = t as NavKey)} />
				{/if}
			{:else if tab === 'fleet'}
				<FleetView store={stores.fleet} />
			{:else if tab === 'routes'}
				<RoutesView
					store={stores.routes}
					autoGroundingThreshold={auth.user?.autoGroundingThreshold ?? 40}
					baseFare={{
						base: stores.simulation.state.ticketBaseFare,
						perKm: stores.simulation.state.ticketPerKmRate
					}}
				/>
			{:else if tab === 'financials'}
				<div class="split">
					<BankView store={stores.bank} />
					<FinanceView store={stores.finance} />
				</div>
			{:else if tab === 'rankings'}
				<LeaderboardView store={stores.leaderboard} />
			{:else if tab === 'settings'}
				<SettingsView store={stores.settings} {auth} />
			{/if}
		</div>
	</div>
</div>

<SkywardSonner
	items={stores.notification.toasts}
	ondismiss={(id) => stores.notification.dismiss(id)}
/>

<style>
	.app {
		display: flex;
		height: 100vh;
		overflow: hidden;
		background: var(--color-bg);
	}
	.main {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
	}
	.content {
		flex: 1;
		min-height: 0;
		overflow-y: auto;
		padding: var(--space-lg);
	}
	.split {
		display: flex;
		flex-direction: column;
		gap: var(--space-lg);
	}
</style>
