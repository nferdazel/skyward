<script lang="ts">
	import CraftCard from '$lib/core/components/CraftCard.svelte';
	import AppBadge from '$lib/core/components/AppBadge.svelte';
	import AppSparkline from '$lib/core/components/AppSparkline.svelte';
	import TactileButton from '$lib/core/components/TactileButton.svelte';
	import { buildOverviewSnapshot, financeTotals } from '../domain/overview-snapshot';
	import type { AppUser } from '$lib/features/auth/domain/user';
	import type { AppStores } from '$lib/core/di/app-stores.svelte';

	/**
	 * Command-center overview. Ported from Flutter `OverviewTab` (desktop
	 * layout): money/runway strip, bankruptcy banner, command deck, priorities.
	 */
	type Props = { stores: AppStores; user: AppUser; onnavigate: (tab: string) => void };
	let { stores, user, onnavigate }: Props = $props();

	const fmt = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${fmt.format(Math.round(n))}`;

	const totals = $derived(financeTotals(stores.finance.state.transactions));
	const overview = $derived(
		buildOverviewSnapshot({
			user,
			sim: stores.simulation.state,
			fleet: stores.fleet.state.aircraft,
			routes: stores.routes.state.routes,
			assessments: stores.routes.state.assessments,
			finance: stores.finance.state.snapshot,
			hasExpenseHistory: totals.totalExpense > 0,
			totalExpense: totals.totalExpense,
			totalRevenue: totals.totalRevenue,
			totalLease: totals.totalLease,
			totalOperations: totals.totalOperations,
			rankings: stores.leaderboard.state.entries,
			netWorthTrend: stores.finance.state.history.map((h) => h.netWorth).reverse(),
			profitTrend: []
		})
	);

	const netWorthTrend = $derived(stores.finance.state.history.map((h) => h.netWorth));

	/** A brand-new airline: nothing to operate yet → show the getting-started guide. */
	const isNewAirline = $derived(overview.totalFleetCount === 0 && overview.activeRoutes === 0);
</script>

<div class="overview">
	<span class="section">Money & runway</span>
	<CraftCard>
		<div class="strip">
			<div class="block runway">
				<span class="k">Runway estimate</span>
				<span class="big" style="color: {overview.runwayColor};">{overview.runwayLabel}</span>
				<div class="badges">
					<AppBadge label={overview.operationalStatus} tone="secondary" />
					<AppBadge label={overview.burnMixLabel} tone="secondary" />
				</div>
				{#if overview.consecutiveNegativeDays > 0 || overview.recoveryStreakDays > 0}
					<div class="mini">
						{#if overview.consecutiveNegativeDays > 0}
							<span class="bad tnum">{overview.consecutiveNegativeDays}d negative</span>
						{/if}
						{#if overview.recoveryStreakDays > 0}
							<span class="good tnum">{overview.recoveryStreakDays}d recovery</span>
						{/if}
					</div>
				{/if}
			</div>

			<span class="vline"></span>

			<div class="block money">
				<span class="k">Cash</span>
				<span class="big tnum" class:bad={stores.simulation.state.cashBalance < 0}>
					{money(stores.simulation.state.cashBalance)}
				</span>
				<div class="metrics">
					<div>
						<span class="k">Revenue 30d</span><span class="ok tnum"
							>{money(stores.finance.state.snapshot.rollingRevenue30d)}</span
						>
					</div>
					<div>
						<span class="k">Expense 30d</span><span class="bad tnum"
							>{money(stores.finance.state.snapshot.rollingExpense30d)}</span
						>
					</div>
					<div>
						<span class="k">Net 30d</span><span class="tnum"
							>{money(stores.finance.state.snapshot.rollingNet30d)}</span
						>
					</div>
				</div>
			</div>

			<span class="vline"></span>

			<div class="block trend">
				<span class="k">Net worth trend</span>
				<AppSparkline values={netWorthTrend} color="var(--color-accent)" />
				<div class="metrics">
					<div>
						<span class="k">Fleet</span><span class="tnum">{overview.totalFleetCount}</span>
					</div>
					<div><span class="k">Routes</span><span class="tnum">{overview.activeRoutes}</span></div>
					<div>
						<span class="k">Idle ready</span><span class="tnum">{overview.idleReadyFleetCount}</span
						>
					</div>
				</div>
			</div>
		</div>
	</CraftCard>

	{#if overview.bankruptcyRiskLevel > 0}
		<div class="banner" class:critical={overview.bankruptcyRiskLevel === 2} role="alert">
			<strong>{overview.bankruptcyRiskLabel}</strong>
			<span
				>Cash is {stores.simulation.state.cashBalance < 0 ? 'negative' : 'at the warning threshold'} —
				take action.</span
			>
		</div>
	{/if}

	{#if isNewAirline}
		<span class="section">Get started</span>
		<CraftCard>
			<div class="onboard">
				<p class="onboard-intro">
					You have {money(stores.simulation.state.cashBalance)} in cash and no aircraft yet. Here is the
					shortest path to your first revenue.
				</p>
				<ol class="steps">
					<li>
						<span class="step-n">1</span>
						<div>
							<span class="step-t">Acquire an aircraft</span>
							<span class="step-d">Buy or lease one — leasing needs less upfront cash.</span>
						</div>
						<TactileButton text="Open Fleet" type="secondary" onclick={() => onnavigate('fleet')} />
					</li>
					<li>
						<span class="step-n">2</span>
						<div>
							<span class="step-t">Open a route</span>
							<span class="step-d">Wire two airports and assign the aircraft to start flying.</span>
						</div>
						<TactileButton
							text="Open Routes"
							type="secondary"
							onclick={() => onnavigate('routes')}
						/>
					</li>
					<li>
						<span class="step-n">3</span>
						<div>
							<span class="step-t">Watch the ledger</span>
							<span class="step-d">Revenue posts automatically each game day.</span>
						</div>
						<TactileButton
							text="Open Financials"
							type="secondary"
							onclick={() => onnavigate('financials')}
						/>
					</li>
				</ol>
			</div>
		</CraftCard>
	{:else}
		<span class="section">Command deck</span>
		<div class="deck">
			<CraftCard onclick={() => onnavigate('fleet')}>
				<span class="k">Fleet readiness</span>
				<span class="big tnum ok">{overview.readyFleetCount} ready</span>
				<span class="muted"
					>{overview.groundedCount} grounded · {overview.leasedCount} leased · avg cond {Math.round(
						overview.averageCondition
					)}%</span
				>
			</CraftCard>
			<CraftCard onclick={() => onnavigate('routes')}>
				<span class="k">Routes</span>
				<span class="big tnum">{overview.activeRoutes}</span>
				<span class="muted"
					>{overview.riskyRoutes} at risk · {overview.avgFlightsPerRouteLabel}</span
				>
				<span class="muted">Top risk: {overview.topRouteRiskLabel}</span>
			</CraftCard>
			<CraftCard onclick={() => onnavigate('rankings')}>
				<span class="k">Leader gap</span>
				<span class="big tnum" style="color: {overview.leaderGapColor};"
					>{overview.leaderGapLabel}</span
				>
				<span class="muted"
					>Leader bot: {overview.leadingBotArchetype} · {overview.leadingBotFleet} aircraft</span
				>
			</CraftCard>
			<CraftCard onclick={() => onnavigate('routes')}>
				<span class="k">Best yield</span>
				<span class="big">{overview.bestRouteYieldLabel}</span>
				<span class="muted">Slack: {Math.round(overview.totalSlackHours)} h/wk</span>
			</CraftCard>
		</div>
	{/if}

	{#if overview.priorities.length > 0}
		<span class="section">Priorities</span>
		<div class="priorities">
			{#each overview.priorities as p, i (i)}
				<CraftCard onclick={() => p.navigateToFleet && onnavigate('fleet')}>
					<span class="prio-label">{p.label}</span>
					<span class="muted">{p.description}</span>
				</CraftCard>
			{/each}
		</div>
	{/if}
</div>

<style>
	.overview {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
	}
	.section {
		font-size: 11px;
		font-weight: 600;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		color: var(--color-text-muted);
	}
	.strip {
		display: flex;
		align-items: stretch;
		gap: var(--space-lg);
	}
	.block {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
	}
	.runway {
		flex: 3;
	}
	.money {
		flex: 5;
	}
	.trend {
		flex: 3;
	}
	.vline {
		width: 1px;
		background: var(--color-border);
	}
	.k {
		font-size: 10px;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--color-text-muted);
	}
	.big {
		font-size: 24px;
		font-weight: 700;
		font-variant-numeric: tabular-nums;
	}
	.badges {
		display: flex;
		gap: var(--space-xs);
		flex-wrap: wrap;
		margin-top: var(--space-xs);
	}
	.mini {
		display: flex;
		gap: var(--space-md);
		margin-top: var(--space-xs);
		font-size: 12px;
	}
	.bad {
		color: var(--color-error);
	}
	.ok,
	.good {
		color: var(--color-success);
	}
	.metrics {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin-top: var(--space-sm);
	}
	.metrics > div {
		display: flex;
		justify-content: space-between;
		gap: var(--space-md);
		font-size: 13px;
	}
	.muted {
		color: var(--color-text-secondary);
		font-size: 12px;
	}
	.banner {
		padding: var(--space-md);
		background: var(--color-warning-subtle);
		border: 1px solid var(--color-warning);
		border-radius: var(--radius-default);
		color: var(--color-warning);
		display: flex;
		gap: var(--space-sm);
		align-items: baseline;
		font-size: 13px;
	}
	.banner.critical {
		background: var(--color-error-subtle);
		border-color: var(--color-error);
		color: var(--color-error);
	}
	.deck {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
		gap: var(--space-md);
	}
	.deck :global(.craft),
	.priorities :global(.craft) {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
	}
	.priorities {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
		gap: var(--space-md);
	}
	.prio-label {
		font-weight: 600;
	}
	.onboard {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
	}
	.onboard-intro {
		margin: 0;
		font-size: 13px;
		color: var(--color-text-secondary);
	}
	.steps {
		list-style: none;
		margin: 0;
		padding: 0;
		display: flex;
		flex-direction: column;
		gap: var(--space-sm);
	}
	.steps li {
		display: flex;
		align-items: center;
		gap: var(--space-md);
		padding: var(--space-sm) 0;
		border-top: 1px solid var(--color-border-subtle);
	}
	.step-n {
		display: grid;
		place-items: center;
		width: 24px;
		height: 24px;
		flex: 0 0 24px;
		border-radius: 50%;
		background: var(--color-accent-subtle);
		color: var(--color-accent);
		font-size: 12px;
		font-weight: 700;
	}
	.steps li > div {
		flex: 1;
		display: flex;
		flex-direction: column;
		gap: 2px;
		min-width: 0;
	}
	.step-t {
		font-weight: 600;
		font-size: 13px;
	}
	.step-d {
		font-size: 12px;
		color: var(--color-text-muted);
	}
</style>
