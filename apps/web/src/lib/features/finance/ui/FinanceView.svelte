<script lang="ts">
	import CraftCard from '$lib/core/components/CraftCard.svelte';
	import AppSparkline from '$lib/core/components/AppSparkline.svelte';
	import SegmentedPillControl from '$lib/core/components/SegmentedPillControl.svelte';
	import BankView from '$lib/features/bank/ui/BankView.svelte';
	import LedgerTable from './LedgerTable.svelte';
	import IfrsReportPanel from './IfrsReportPanel.svelte';
	import type { FinanceStore } from '../state/finance-store.svelte';
	import type { BankStore } from '$lib/features/bank/state/bank-store.svelte';
	import { buildFinanceOverview, operatingMargin } from '../domain/finance-overview';
	import { financeTotals } from '$lib/features/dashboard/domain/overview-snapshot';
	import { colors } from '$lib/core/theme/tokens';

	/**
	 * Finance view. Ported from Flutter `FinanceView`: 4 segmented tabs
	 * (Overview / Ledger / Reports / Bank). Overview = health hero KPI row;
	 * Reports = IFRS panel; Bank reuses the bank panel.
	 */
	type Props = { store: FinanceStore; bankStore: BankStore };
	let { store, bankStore }: Props = $props();

	let tab = $state<'overview' | 'ledger' | 'reports' | 'bank'>('overview');

	const fmt = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${fmt.format(Math.round(n))}`;

	const totals = $derived(financeTotals(store.state.transactions));
	const snapshot = $derived(store.state.snapshot);
	const weeklyDebt = $derived(
		bankStore.state.loans
			.filter((l) => l.status === 'active')
			.reduce((s, l) => s + l.weeklyPayment, 0)
	);

	const overview = $derived(
		buildFinanceOverview({
			snapshot,
			totalLease: totals.totalLease,
			totalOperations: totals.totalOperations,
			totalRepair: 0,
			totalPurchase: 0,
			totalExpense: totals.totalExpense,
			weeklyDebtPayment: weeklyDebt
		})
	);

	const margin = $derived(operatingMargin(totals.totalRevenue, totals.totalExpense));
	const net30d = $derived(snapshot.rollingNet30d);

	const cashTrend = $derived(snapshot.cash > 0 ? [snapshot.cash, snapshot.cash] : [0, 0]);
	const netWorthTrend = $derived(
		snapshot.netWorth > 0 ? [snapshot.netWorth, snapshot.netWorth] : [0, 0]
	);

	const coverageColor = $derived(
		overview.coverageColor === 'success' ? colors.success : colors.warning
	);
	const marginColor = $derived(
		margin > 20 ? colors.success : margin > 5 ? colors.warning : colors.error
	);
	const netColor = $derived(net30d >= 0 ? colors.success : colors.error);
</script>

<section>
	<SegmentedPillControl
		items={[
			{ value: 'overview', label: 'Overview' },
			{ value: 'ledger', label: 'Ledger' },
			{ value: 'reports', label: 'Reports' },
			{ value: 'bank', label: 'Bank' }
		]}
		selected={tab}
		onselect={(v) => (tab = v as 'overview' | 'ledger' | 'reports' | 'bank')}
	/>

	{#if tab === 'overview'}
		{#if store.state.loading && store.state.transactions.length === 0}
			<p class="muted" role="status" aria-live="polite">Loading financial data…</p>
		{/if}
		<CraftCard>
			<div class="hero">
				<div class="kpi">
					<span class="k">Cash</span>
					<span class="v tnum">{money(snapshot.cash)}</span>
					<AppSparkline values={cashTrend} color="var(--color-accent)" />
				</div>
				<span class="vline"></span>
				<div class="kpi">
					<span class="k">Net worth</span>
					<span class="v tnum" style="color: {colors.accent};">{money(snapshot.netWorth)}</span>
					<div class="sub-row">
						<AppSparkline values={netWorthTrend} color="var(--color-accent)" />
						<span class="muted"
							>{snapshot.ownedFleetCount} owned / {snapshot.leasedFleetCount} leased</span
						>
					</div>
				</div>
				<span class="vline"></span>
				<div class="kpi">
					<span class="k">Net 30d</span>
					<span class="v tnum" style="color: {netColor};"
						>{net30d >= 0 ? '+' : '-'}{money(Math.abs(net30d))}</span
					>
					<div class="sub-row">
						<span style="color: {netColor};">{net30d >= 0 ? 'Profit' : 'Loss'}</span>
					</div>
				</div>
				<span class="vline"></span>
				<div class="kpi">
					<span class="k">Runway</span>
					<span class="v" style="color: {overview.runwayColor};">{overview.runwayLabel}</span>
					<span class="muted" title={overview.runwayVerdict} style="color: {coverageColor};"
						>{overview.coverageLabel}</span
					>
				</div>
				<span class="vline"></span>
				<div class="kpi">
					<span class="k">Margin</span>
					<span class="v" style="color: {marginColor};">{margin.toFixed(1)}%</span>
					<span class="muted">{overview.burnMixLabel}</span>
				</div>
			</div>
		</CraftCard>

		<div class="zones">
			<CraftCard>
				<span class="k">Largest expense</span>
				<span class="v">{overview.largestExpenseLabel}</span>
			</CraftCard>
			<CraftCard>
				<span class="k">Revenue 30d</span>
				<span class="v tnum ok">{money(snapshot.rollingRevenue30d)}</span>
			</CraftCard>
			<CraftCard>
				<span class="k">Expense 30d</span>
				<span class="v tnum bad">{money(snapshot.rollingExpense30d)}</span>
			</CraftCard>
			<CraftCard>
				<span class="k">Weekly debt service</span>
				<span class="v tnum warn">{money(weeklyDebt)}</span>
			</CraftCard>
		</div>
	{:else if tab === 'ledger'}
		<LedgerTable {store} />
	{:else if tab === 'reports'}
		<IfrsReportPanel {store} {bankStore} />
	{:else}
		<BankView store={bankStore} />
	{/if}
</section>

<style>
	section {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
	}
	.hero {
		display: flex;
		align-items: stretch;
		gap: var(--space-lg);
		flex-wrap: wrap;
	}
	.kpi {
		flex: 1;
		min-width: 150px;
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
	}
	.k {
		font-size: 10px;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--color-text-muted);
	}
	.v {
		font-size: 20px;
		font-weight: 700;
		font-variant-numeric: tabular-nums;
	}
	.sub-row {
		display: flex;
		align-items: center;
		gap: var(--space-xs);
	}
	.muted {
		font-size: 11px;
		color: var(--color-text-muted);
	}
	.vline {
		width: 1px;
		background: var(--color-border);
	}
	.zones {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
		gap: var(--space-md);
	}
	.zones :global(.craft) {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
	}
	.ok {
		color: var(--color-success);
	}
	.bad {
		color: var(--color-error);
	}
	.warn {
		color: var(--color-warning);
	}
</style>
