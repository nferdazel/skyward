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
			Ringkasan
		</button>
		<button
			role="tab"
			aria-selected={view === 'ifrs'}
			class:active={view === 'ifrs'}
			onclick={() => (view = 'ifrs')}
		>
			Laporan IFRS
		</button>
	</div>

	{#if view === 'overview'}
		<div class="grid">
			<AppCard>
				<h3>Kas</h3>
				<span class="big">{money(snapshot.cash)}</span>
			</AppCard>
			<AppCard>
				<h3>Nilai bersih</h3>
				<span class="big">{money(snapshot.netWorth)}</span>
			</AppCard>
			<AppCard>
				<h3>Pendapatan 30h</h3>
				<span class="big success">{money(snapshot.rollingRevenue30d)}</span>
			</AppCard>
			<AppCard>
				<h3>Beban 30h</h3>
				<span class="big error">{money(snapshot.rollingExpense30d)}</span>
			</AppCard>
			<AppCard>
				<h3>Bersih 30h</h3>
				<span
					class="big"
					class:success={snapshot.rollingNet30d >= 0}
					class:error={snapshot.rollingNet30d < 0}
				>
					{money(snapshot.rollingNet30d)}
				</span>
			</AppCard>
			<AppCard>
				<h3>Armada / rute</h3>
				<span class="big">{snapshot.fleetCount} / {snapshot.activeRouteCount}</span>
			</AppCard>
		</div>
	{:else if store.state.transactions.length === 0}
		<AppEmptyState title="Belum ada transaksi" description="Laporan IFRS butuh data ledger." />
	{:else}
		<div class="grid ifrs">
			<AppCard>
				<h3>Laba / Rugi</h3>
				<table>
					<tbody>
						<tr><td>Penjualan tiket</td><td>{money(income.ticketSales)}</td></tr>
						<tr><td>Kargo</td><td>{money(income.cargoRevenue)}</td></tr>
						<tr class="total"><td>Total pendapatan</td><td>{money(income.totalRevenue)}</td></tr>
						<tr><td>Bahan bakar</td><td>{money(income.fuel)}</td></tr>
						<tr><td>Kru</td><td>{money(income.crew)}</td></tr>
						<tr><td>Pemeliharaan</td><td>{money(income.maintenance)}</td></tr>
						<tr><td>Biaya bandara</td><td>{money(income.airportFees)}</td></tr>
						<tr><td>Sewa armada</td><td>{money(income.fleetLeasing)}</td></tr>
						<tr><td>Perbaikan</td><td>{money(income.hangarRepairs)}</td></tr>
						<tr class="total"
							><td>Total biaya operasi</td><td>{money(income.totalOperatingCosts)}</td></tr
						>
						<tr class="total"><td>Laba bersih</td><td>{money(income.netIncome)}</td></tr>
					</tbody>
				</table>
			</AppCard>

			<AppCard>
				<h3>Neraca</h3>
				<table>
					<tbody>
						<tr><td>Kas</td><td>{money(sheet.cash)}</td></tr>
						<tr><td>Nilai armada</td><td>{money(sheet.fleetNetBookValue)}</td></tr>
						<tr class="total"><td>Total aset</td><td>{money(sheet.totalAssets)}</td></tr>
						<tr><td>Pinjaman</td><td>{money(sheet.outstandingLoans)}</td></tr>
						<tr class="total"><td>Total liabilitas</td><td>{money(sheet.totalLiabilities)}</td></tr>
						<tr class="total"><td>Ekuitas</td><td>{money(sheet.totalEquity)}</td></tr>
					</tbody>
				</table>
			</AppCard>

			<AppCard>
				<h3>Arus kas</h3>
				<table>
					<tbody>
						<tr><td>Masuk operasi</td><td>{money(cashflows.revenueInflows)}</td></tr>
						<tr><td>Keluar operasi</td><td>{money(cashflows.operatingOutflows)}</td></tr>
						<tr class="total"><td>Arus operasi</td><td>{money(cashflows.operatingCashFlow)}</td></tr
						>
						<tr><td>Belanja modal</td><td>{money(cashflows.capitalExpenditure)}</td></tr>
						<tr><td>Penjualan pesawat</td><td>{money(cashflows.aircraftSales)}</td></tr>
						<tr class="total"
							><td>Arus investasi</td><td>{money(cashflows.investingCashFlow)}</td></tr
						>
						<tr><td>Pencairan pinjaman</td><td>{money(cashflows.loanProceeds)}</td></tr>
						<tr><td>Pembayaran pinjaman</td><td>{money(cashflows.loanRepayments)}</td></tr>
						<tr class="total"
							><td>Arus pendanaan</td><td>{money(cashflows.financingCashFlow)}</td></tr
						>
						<tr class="total"
							><td>Perubahan kas bersih</td><td>{money(cashflows.netCashChange)}</td></tr
						>
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
