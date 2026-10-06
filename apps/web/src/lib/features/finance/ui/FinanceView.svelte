<script lang="ts">
	import AppCard from '$lib/core/components/AppCard.svelte';
	import AppEmptyState from '$lib/core/components/AppEmptyState.svelte';
	import type { FinanceStore } from '../state/finance-store.svelte';
	import {
		buildBalanceSheet,
		buildCashFlows,
		buildIncomeStatement
	} from '../domain/ifrs-report-builder';

	type Props = { store: FinanceStore };
	let { store }: Props = $props();

	let view = $state<'overview' | 'ifrs'>('overview');

	const num = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${num.format(Math.round(n))}`;

	// Laporan disusun dari transaksi (agregasi tampilan, bukan ekonomi otoritatif).
	const income = $derived(buildIncomeStatement(store.state.transactions));
	const cashflows = $derived(buildCashFlows(store.state.transactions));
	// Liabilitas pinjaman berasal dari store bank; bila tak disediakan, 0
	// (neraca tetap seimbang karena ekuitas = residual).
	const sheet = $derived(buildBalanceSheet(store.state.snapshot, 0));
	const snapshot = $derived(store.state.snapshot);
</script>

<section>
	<div class="tabs" role="tablist">
		<button
			role="tab"
			aria-selected={view === 'overview'}
			class:active={view === 'overview'}
			onclick={() => (view = 'overview')}
		>
			Overview
		</button>
		<button
			role="tab"
			aria-selected={view === 'ifrs'}
			class:active={view === 'ifrs'}
			onclick={() => (view = 'ifrs')}
		>
			IFRS report
		</button>
	</div>

	{#if view === 'overview'}
		<div class="grid">
			<AppCard>
				<h3>Cash</h3>
				<span class="big">{money(snapshot.cash)}</span>
			</AppCard>
			<AppCard>
				<h3>Net worth</h3>
				<span class="big">{money(snapshot.netWorth)}</span>
			</AppCard>
			<AppCard>
				<h3>Revenue 30d</h3>
				<span class="big success">{money(snapshot.rollingRevenue30d)}</span>
			</AppCard>
			<AppCard>
				<h3>Expense 30d</h3>
				<span class="big error">{money(snapshot.rollingExpense30d)}</span>
			</AppCard>
			<AppCard>
				<h3>Net 30d</h3>
				<span
					class="big"
					class:success={snapshot.rollingNet30d >= 0}
					class:error={snapshot.rollingNet30d < 0}
				>
					{money(snapshot.rollingNet30d)}
				</span>
			</AppCard>
			<AppCard>
				<h3>Fleet / routes</h3>
				<span class="big">{snapshot.fleetCount} / {snapshot.activeRouteCount}</span>
			</AppCard>
		</div>
	{:else if store.state.transactions.length === 0}
		<AppEmptyState title="No transactions" description="The IFRS report needs ledger data." />
	{:else}
		<div class="grid ifrs">
			<AppCard>
				<h3>Profit & Loss</h3>
				<table>
					<tbody>
						<tr><td>Ticket sales</td><td>{money(income.ticketSales)}</td></tr>
						<tr><td>Cargo</td><td>{money(income.cargoRevenue)}</td></tr>
						<tr class="total"><td>Total revenue</td><td>{money(income.totalRevenue)}</td></tr>
						<tr><td>Fuel</td><td>{money(income.fuel)}</td></tr>
						<tr><td>Crew</td><td>{money(income.crew)}</td></tr>
						<tr><td>Maintenance</td><td>{money(income.maintenance)}</td></tr>
						<tr><td>Airport fees</td><td>{money(income.airportFees)}</td></tr>
						<tr><td>Fleet leasing</td><td>{money(income.fleetLeasing)}</td></tr>
						<tr><td>Repairs</td><td>{money(income.hangarRepairs)}</td></tr>
						<tr class="total"
							><td>Total operating costs</td><td>{money(income.totalOperatingCosts)}</td></tr
						>
						<tr class="total"><td>Net income</td><td>{money(income.netIncome)}</td></tr>
					</tbody>
				</table>
			</AppCard>

			<AppCard>
				<h3>Balance sheet</h3>
				<table>
					<tbody>
						<tr><td>Cash</td><td>{money(sheet.cash)}</td></tr>
						<tr><td>Fleet value</td><td>{money(sheet.fleetNetBookValue)}</td></tr>
						<tr class="total"><td>Total assets</td><td>{money(sheet.totalAssets)}</td></tr>
						<tr><td>Loans</td><td>{money(sheet.outstandingLoans)}</td></tr>
						<tr class="total"><td>Total liabilities</td><td>{money(sheet.totalLiabilities)}</td></tr
						>
						<tr class="total"><td>Equity</td><td>{money(sheet.totalEquity)}</td></tr>
					</tbody>
				</table>
			</AppCard>

			<AppCard>
				<h3>Cash flows</h3>
				<table>
					<tbody>
						<tr><td>Operating inflow</td><td>{money(cashflows.revenueInflows)}</td></tr>
						<tr><td>Operating outflow</td><td>{money(cashflows.operatingOutflows)}</td></tr>
						<tr class="total"
							><td>Operating cash flow</td><td>{money(cashflows.operatingCashFlow)}</td></tr
						>
						<tr><td>Capital expenditure</td><td>{money(cashflows.capitalExpenditure)}</td></tr>
						<tr><td>Aircraft sales</td><td>{money(cashflows.aircraftSales)}</td></tr>
						<tr class="total"
							><td>Investing cash flow</td><td>{money(cashflows.investingCashFlow)}</td></tr
						>
						<tr><td>Loan proceeds</td><td>{money(cashflows.loanProceeds)}</td></tr>
						<tr><td>Loan repayments</td><td>{money(cashflows.loanRepayments)}</td></tr>
						<tr class="total"
							><td>Financing cash flow</td><td>{money(cashflows.financingCashFlow)}</td></tr
						>
						<tr class="total"><td>Net cash change</td><td>{money(cashflows.netCashChange)}</td></tr>
					</tbody>
				</table>
			</AppCard>
		</div>
	{/if}
</section>

<style>
	.tabs {
		display: flex;
		gap: var(--space-sm);
		margin-bottom: var(--space-md);
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
		text-transform: uppercase;
	}
	.tabs button.active {
		color: var(--color-accent);
		border-bottom-color: var(--color-accent);
	}
	.grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
		gap: var(--space-md);
	}
	.ifrs {
		grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
	}
	h3 {
		margin: 0 0 var(--space-sm);
		font-size: 12px;
		letter-spacing: 0.06em;
		text-transform: uppercase;
		color: var(--color-text-secondary);
	}
	.big {
		font-size: 22px;
		font-variant-numeric: tabular-nums;
	}
	.success {
		color: var(--color-success);
	}
	.error {
		color: var(--color-error);
	}
	table {
		width: 100%;
		border-collapse: collapse;
		font-size: 13px;
	}
	td {
		padding: var(--space-xs) 0;
		border-bottom: 0.5px solid var(--color-border-subtle);
	}
	td:last-child {
		text-align: right;
		font-variant-numeric: tabular-nums;
	}
	tr.total td {
		font-weight: 600;
		color: var(--color-text-primary);
		border-bottom-color: var(--color-border);
	}
</style>
