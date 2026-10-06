<script lang="ts">
	import AppBadge from '$lib/core/components/AppBadge.svelte';
	import type { FinanceStore } from '../state/finance-store.svelte';
	import type { BankStore } from '$lib/features/bank/state/bank-store.svelte';
	import {
		buildBalanceSheet,
		buildCashFlows,
		buildIncomeStatement,
		isBalanced
	} from '../domain/ifrs-report-builder';

	/**
	 * IFRS report panel. Ported from Flutter `IfrsReportBody`: income statement,
	 * balance sheet (with a balance check) and cash-flow statement, built from
	 * the ledger. Outstanding loans come from the bank store.
	 */
	type Props = { store: FinanceStore; bankStore: BankStore };
	let { store, bankStore }: Props = $props();

	const fmt = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${fmt.format(Math.round(n))}`;

	const income = $derived(buildIncomeStatement(store.state.transactions));
	const cashflows = $derived(buildCashFlows(store.state.transactions));
	const outstanding = $derived(
		bankStore.state.loans
			.filter((l) => l.status === 'active')
			.reduce((s, l) => s + l.remainingBalance, 0)
	);
	const sheet = $derived(buildBalanceSheet(store.state.snapshot, outstanding));
	const balanced = $derived(isBalanced(sheet));
</script>

<div class="ifrs">
	<section class="report">
		<h3>Income statement</h3>
		<table>
			<tbody>
				<tr><td>Ticket sales</td><td class="right tnum">{money(income.ticketSales)}</td></tr>
				<tr><td>Cargo</td><td class="right tnum">{money(income.cargoRevenue)}</td></tr>
				<tr class="total"
					><td>Total revenue</td><td class="right tnum">{money(income.totalRevenue)}</td></tr
				>
				<tr><td>Fuel</td><td class="right tnum">{money(income.fuel)}</td></tr>
				<tr><td>Crew</td><td class="right tnum">{money(income.crew)}</td></tr>
				<tr><td>Maintenance</td><td class="right tnum">{money(income.maintenance)}</td></tr>
				<tr><td>Airport fees</td><td class="right tnum">{money(income.airportFees)}</td></tr>
				<tr><td>Fleet leasing</td><td class="right tnum">{money(income.fleetLeasing)}</td></tr>
				<tr><td>Hangar repairs</td><td class="right tnum">{money(income.hangarRepairs)}</td></tr>
				<tr class="total"
					><td>Total operating costs</td><td class="right tnum"
						>{money(income.totalOperatingCosts)}</td
					></tr
				>
				<tr class="total"
					><td>Net income</td><td class="right tnum">{money(income.netIncome)}</td></tr
				>
			</tbody>
		</table>
	</section>

	<section class="report">
		<h3>Balance sheet</h3>
		<table>
			<tbody>
				<tr><td>Cash</td><td class="right tnum">{money(sheet.cash)}</td></tr>
				<tr
					><td>Fleet net book value</td><td class="right tnum">{money(sheet.fleetNetBookValue)}</td
					></tr
				>
				<tr class="total"
					><td>Total assets</td><td class="right tnum">{money(sheet.totalAssets)}</td></tr
				>
				<tr
					><td>Outstanding loans</td><td class="right tnum">{money(sheet.outstandingLoans)}</td></tr
				>
				<tr class="total"
					><td>Total liabilities</td><td class="right tnum">{money(sheet.totalLiabilities)}</td></tr
				>
				<tr class="total"><td>Equity</td><td class="right tnum">{money(sheet.totalEquity)}</td></tr>
			</tbody>
		</table>
		<div class="check">
			<AppBadge
				label={balanced ? 'balanced' : 'unbalanced'}
				tone={balanced ? 'success' : 'error'}
			/>
			<span class="muted">Assets = Liabilities + Equity (residual equity)</span>
		</div>
	</section>

	<section class="report">
		<h3>Cash flows</h3>
		<table>
			<tbody>
				<tr
					><td>Operating inflows</td><td class="right tnum">{money(cashflows.revenueInflows)}</td
					></tr
				>
				<tr
					><td>Operating outflows</td><td class="right tnum"
						>{money(cashflows.operatingOutflows)}</td
					></tr
				>
				<tr class="total"
					><td>Operating cash flow</td><td class="right tnum"
						>{money(cashflows.operatingCashFlow)}</td
					></tr
				>
				<tr
					><td>Capital expenditure</td><td class="right tnum"
						>{money(cashflows.capitalExpenditure)}</td
					></tr
				>
				<tr><td>Aircraft sales</td><td class="right tnum">{money(cashflows.aircraftSales)}</td></tr>
				<tr class="total"
					><td>Investing cash flow</td><td class="right tnum"
						>{money(cashflows.investingCashFlow)}</td
					></tr
				>
				<tr><td>Loan proceeds</td><td class="right tnum">{money(cashflows.loanProceeds)}</td></tr>
				<tr
					><td>Loan repayments</td><td class="right tnum">{money(cashflows.loanRepayments)}</td></tr
				>
				<tr class="total"
					><td>Financing cash flow</td><td class="right tnum"
						>{money(cashflows.financingCashFlow)}</td
					></tr
				>
				<tr class="total"
					><td>Net cash change</td><td class="right tnum">{money(cashflows.netCashChange)}</td></tr
				>
			</tbody>
		</table>
	</section>
</div>

<style>
	.ifrs {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
		gap: var(--space-md);
	}
	.report {
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		padding: var(--space-md);
		background: var(--color-surface);
	}
	h3 {
		margin: 0 0 var(--space-sm);
		font-size: 12px;
		letter-spacing: 0.06em;
		text-transform: uppercase;
		color: var(--color-text-secondary);
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
	.right {
		text-align: right;
	}
	tr.total td {
		font-weight: 700;
		border-bottom-color: var(--color-border);
	}
	.check {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
		margin-top: var(--space-sm);
	}
	.muted {
		font-size: 11px;
		color: var(--color-text-muted);
	}
</style>
