<script lang="ts">
	import AppButton from '$lib/core/components/AppButton.svelte';
	import AppCard from '$lib/core/components/AppCard.svelte';
	import AppBadge from '$lib/core/components/AppBadge.svelte';
	import FleetView from '$lib/features/fleet/ui/FleetView.svelte';
	import RoutesView from '$lib/features/routes/ui/RoutesView.svelte';
	import BankView from '$lib/features/bank/ui/BankView.svelte';
	import FinanceView from '$lib/features/finance/ui/FinanceView.svelte';
	import LeaderboardView from '$lib/features/leaderboard/ui/LeaderboardView.svelte';
	import SettingsView from '$lib/features/settings/ui/SettingsView.svelte';
	import SkywardSonner from '$lib/core/components/SkywardSonner.svelte';
	import { getAuthStore } from '$lib/features/auth/state/auth-context.svelte';
	import { getAppStores } from '$lib/core/di/stores-context.svelte';

	const auth = getAuthStore();
	const stores = getAppStores();

	const fmt = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${fmt.format(Math.round(n))}`;

	const tabs = [
		'Overview',
		'Armada',
		'Rute',
		'Bank',
		'Keuangan',
		'Peringkat',
		'Pengaturan'
	] as const;
	type Tab = (typeof tabs)[number];
	let tab = $state<Tab>('Overview');

	// Leaderboard dimuat lazy saat tab pertama dibuka.
	// Leaderboard dimuat lazy saat tab pertama dibuka.
	$effect(() => {
		if (tab === 'Peringkat' && stores.leaderboard.state.entries.length === 0) {
			void stores.leaderboard.load();
		}
	});

	// Achievement baru dari sync → toast (sekali per kemunculan).
	let seenAchievements = new Set<string>();
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

<svelte:head><title>Skyward — Dashboard</title></svelte:head>

<main class="shell">
	<header>
		<span class="brand">SKYWARD</span>
		{#if auth.user}
			<span class="who">{auth.user.companyName || auth.user.username}</span>
		{/if}
		<AppButton text="Keluar" variant="secondary" onclick={() => auth.logout()} />
	</header>

	<nav class="tabs">
		{#each tabs as t (t)}
			<button
				class:active={tab === t}
				aria-current={tab === t ? 'page' : undefined}
				onclick={() => (tab = t)}
			>
				{t}
			</button>
		{/each}
	</nav>

	{#if tab === 'Overview'}
		<section class="grid">
			<AppCard>
				<h2>Simulasi</h2>
				<p class="muted">
					Waktu game: {stores.simulation.state.gameTime}
					{#if stores.simulation.state.isSyncing}<AppBadge label="sync" tone="primary" />{/if}
				</p>
				<dl>
					<div>
						<dt>Kas</dt>
						<dd>{money(stores.simulation.state.cashBalance)}</dd>
					</div>
					<div>
						<dt>Penerbangan terakhir</dt>
						<dd>{stores.simulation.state.lastFlightsRun}</dd>
					</div>
					<div>
						<dt>Status</dt>
						<dd>{stores.simulation.state.operationalStatus}</dd>
					</div>
				</dl>
			</AppCard>

			<AppCard>
				<h2>Armada</h2>
				<p class="muted">{stores.fleet.state.aircraft.length} pesawat</p>
				<ul>
					{#each stores.fleet.state.aircraft as a (a.id)}
						<li>
							{a.nickname || a.tailNumber || a.model.modelName}
							— <span class="muted">{Math.round(a.condition)}%</span>
						</li>
					{:else}
						<li class="muted">Belum ada pesawat.</li>
					{/each}
				</ul>
			</AppCard>

			<AppCard>
				<h2>Rute</h2>
				<p class="muted">{stores.routes.state.routes.length} rute aktif</p>
				<ul>
					{#each stores.routes.state.routes as r (r.id)}
						<li>
							{r.originIata}→{r.destinationIata}
							<span class="muted">({Math.round(r.distanceKm)} km, {r.flightsPerWeek}/wk)</span>
						</li>
					{:else}
						<li class="muted">Belum ada rute.</li>
					{/each}
				</ul>
			</AppCard>

			<AppCard>
				<h2>Bank</h2>
				<dl>
					<div>
						<dt>Akun operasional</dt>
						<dd>{money(stores.bank.operatingAccount?.balance ?? 0)}</dd>
					</div>
					<div>
						<dt>Pinjaman</dt>
						<dd>{stores.bank.state.loans.length}</dd>
					</div>
					<div>
						<dt>Tier kredit</dt>
						<dd>{stores.bank.state.credit?.creditTier ?? '—'}</dd>
					</div>
				</dl>
			</AppCard>

			<AppCard>
				<h2>Keuangan</h2>
				<dl>
					<div>
						<dt>Pendapatan 30h</dt>
						<dd>{money(stores.finance.state.snapshot.rollingRevenue30d)}</dd>
					</div>
					<div>
						<dt>Beban 30h</dt>
						<dd>{money(stores.finance.state.snapshot.rollingExpense30d)}</dd>
					</div>
					<div>
						<dt>Bersih 30h</dt>
						<dd>{money(stores.finance.state.snapshot.rollingNet30d)}</dd>
					</div>
				</dl>
			</AppCard>

			<AppCard>
				<h2>Event dunia</h2>
				<ul>
					{#each stores.events.state.events as e (e.id)}
						<li>{e.title} <span class="muted">{e.eventType}</span></li>
					{:else}
						<li class="muted">Tidak ada event aktif.</li>
					{/each}
				</ul>
			</AppCard>
		</section>
	{:else if tab === 'Armada'}
		<FleetView store={stores.fleet} />
	{:else if tab === 'Rute'}
		<RoutesView store={stores.routes} />
	{:else if tab === 'Bank'}
		<BankView store={stores.bank} />
	{:else if tab === 'Keuangan'}
		<FinanceView store={stores.finance} />
	{:else if tab === 'Peringkat'}
		<LeaderboardView store={stores.leaderboard} />
	{:else if tab === 'Pengaturan'}
		<SettingsView store={stores.settings} {auth} />
	{:else}
		<AppCard>
			<p class="muted">Tab «{tab}» menyusul sesuai backlog.</p>
		</AppCard>
	{/if}
</main>

<SkywardSonner
	items={stores.notification.toasts}
	ondismiss={(id) => stores.notification.dismiss(id)}
/>

<style>
	.shell {
		min-height: 100vh;
		background: var(--color-bg);
		padding: var(--space-lg);
	}
	header {
		display: flex;
		align-items: center;
		gap: var(--space-md);
		padding-bottom: var(--space-lg);
	}
	.brand {
		color: var(--color-accent);
		font-weight: 700;
		letter-spacing: 0.3em;
	}
	.who {
		margin-left: auto;
		color: var(--color-text-secondary);
		font-size: 13px;
	}
	.tabs {
		display: flex;
		gap: var(--space-sm);
		margin-bottom: var(--space-lg);
		border-bottom: 0.5px solid var(--color-border);
	}
	.tabs button {
		background: transparent;
		border: none;
		border-bottom: 2px solid transparent;
		color: var(--color-text-secondary);
		padding: var(--space-sm) var(--space-md);
		cursor: pointer;
		font-family: var(--font-sans);
		font-weight: 600;
		font-size: 12px;
		letter-spacing: 0.06em;
	}
	.tabs button.active {
		color: var(--color-accent);
		border-bottom-color: var(--color-accent);
	}
	.grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
		gap: var(--space-md);
	}
	h2 {
		margin: 0 0 var(--space-sm);
		font-size: 14px;
		letter-spacing: 0.06em;
		text-transform: uppercase;
		color: var(--color-text-primary);
	}
	.muted {
		color: var(--color-text-muted);
		font-size: 12px;
	}
	ul {
		list-style: none;
		padding: 0;
		margin: var(--space-sm) 0 0;
		font-size: 13px;
	}
	li {
		padding: var(--space-xs) 0;
		border-bottom: 0.5px solid var(--color-border-subtle);
	}
	dl {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin: var(--space-sm) 0 0;
	}
	dl > div {
		display: flex;
		justify-content: space-between;
		gap: var(--space-md);
	}
	dt {
		color: var(--color-text-muted);
		font-size: 11px;
		text-transform: uppercase;
		letter-spacing: 0.08em;
	}
	dd {
		margin: 0;
		font-size: 14px;
	}
</style>
