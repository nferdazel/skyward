<script lang="ts">
	import AppSidebar from '$lib/core/components/AppSidebar.svelte';
	import type { NavKey } from '$lib/core/components/nav';
	import TopHud from '$lib/core/components/TopHud.svelte';
	import SkywardSonner from '$lib/core/components/SkywardSonner.svelte';
	import OnboardingOverlay from '$lib/core/components/OnboardingOverlay.svelte';
	import WhileAwayDigest from '$lib/core/components/WhileAwayDigest.svelte';
	import OverviewTab from '$lib/features/dashboard/ui/OverviewTab.svelte';
	import FleetView from '$lib/features/fleet/ui/FleetView.svelte';
	import RoutesView from '$lib/features/routes/ui/RoutesView.svelte';
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

	// "While you were away" digest: after returning with >= 1 game day elapsed,
	// shown once per game time, never stacked on onboarding.
	let showDigest = $state(false);
	let lastDigestGameTime = '';
	$effect(() => {
		const sim = stores.simulation.state;
		if (sim.isSyncing || sim.lastElapsedDays < 1) return;
		if (auth.user && !auth.user.onboardingCompleted) return;
		if (lastDigestGameTime === sim.gameTime) return;
		lastDigestGameTime = sim.gameTime;
		showDigest = true;
	});
	function dismissDigest() {
		showDigest = false;
	}
</script>

<svelte:head><title>Skyward — Command Center</title></svelte:head>

<div class="app">
	<AppSidebar active={tab} onselect={(k) => (tab = k)} onlogout={() => auth.logout()} />

	<div class="main">
		{#if auth.user}
			<TopHud user={auth.user} sim={stores.simulation.state} notifications={stores.notification} />
		{/if}

		{#if stores.simulation.state.errorMessage}
			<div class="net-status" role="alert">
				<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
					<path
						d="M2 22 22 2m-9 14h-2m13.5 2 1.5 1.5M8.5 8.5A10 10 0 0 0 2 12m0-8 20 20"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
					/>
				</svg>
				<span>Connection lost — retrying. {stores.simulation.state.errorMessage}</span>
			</div>
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
				<FinanceView store={stores.finance} bankStore={stores.bank} />
			{:else if tab === 'rankings'}
				<LeaderboardView store={stores.leaderboard} currentUserId={auth.user?.id} />
			{:else if tab === 'settings'}
				<SettingsView
					store={stores.settings}
					user={auth.user}
					onsaved={() => void stores.simulation.syncWithDatabase()}
					ondeleted={() => auth.logout()}
				/>
			{/if}
		</div>
	</div>
</div>

<SkywardSonner
	items={stores.notification.toasts}
	ondismiss={(id) => stores.notification.dismiss(id)}
/>

{#if auth.user && !auth.user.onboardingCompleted}
	<OnboardingOverlay
		onnavigate={(t) => (tab = t as NavKey)}
		oncomplete={() => {
			auth.markOnboardingCompleted();
			void stores.simulation.markOnboardingComplete();
		}}
	/>
{/if}

{#if showDigest}
	<WhileAwayDigest
		elapsedDays={stores.simulation.state.lastElapsedDays}
		flightsRun={stores.simulation.state.lastFlightsRun}
		revenue={stores.simulation.state.lastRevenue}
		expense={stores.simulation.state.lastExpense}
		onclose={dismissDigest}
	/>
{/if}

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
	.net-status {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
		padding: var(--space-sm) var(--space-md);
		background: var(--color-error-subtle);
		border-bottom: 1px solid var(--color-error);
		color: var(--color-error);
		font-size: 12px;
	}
</style>
