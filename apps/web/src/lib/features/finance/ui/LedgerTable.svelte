<script lang="ts">
	import CraftCard from '$lib/core/components/CraftCard.svelte';
	import AppBadge from '$lib/core/components/AppBadge.svelte';
	import type { FinanceStore } from '../state/finance-store.svelte';
	import { groupFor, type IfrsGroup } from '../domain/ifrs-category';
	import type { BankTransaction } from '$lib/features/bank/domain/bank-models';

	/**
	 * Ledger tab. Ported from Flutter `FinanceLedgerFilters` + transactions table:
	 * a filter strip by IFRS group over the transaction list.
	 */
	type Props = { store: FinanceStore };
	let { store }: Props = $props();

	type Filter = 'all' | IfrsGroup;
	let filter = $state<Filter>('all');

	const fmt = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${fmt.format(Math.round(n))}`;

	function groupOf(t: BankTransaction): IfrsGroup {
		const key = t.ifrsSubcategory || t.ifrsCategory || '';
		return groupFor(key);
	}

	const filters: { value: Filter; label: string }[] = [
		{ value: 'all', label: 'All' },
		{ value: 'ticketSales', label: 'Revenue' },
		{ value: 'operations', label: 'Operations' },
		{ value: 'lease', label: 'Lease' },
		{ value: 'repair', label: 'Repairs' },
		{ value: 'purchase', label: 'Acquisition' },
		{ value: 'financing', label: 'Financing' }
	];

	const filtered = $derived(
		filter === 'all'
			? store.state.transactions
			: store.state.transactions.filter((t) => groupOf(t) === filter)
	);

	function tone(t: BankTransaction): 'success' | 'error' {
		return t.transactionType === 'credit' ? 'success' : 'error';
	}
</script>

<div class="ledger">
	<div class="filters">
		{#each filters as f (f.value)}
			<button class:active={filter === f.value} onclick={() => (filter = f.value)}>{f.label}</button
			>
		{/each}
	</div>

	<CraftCard>
		{#if filtered.length === 0}
			<p class="muted">No transactions.</p>
		{:else}
			<div class="table-wrap">
				<table>
					<thead>
						<tr>
							<th>Game date</th>
							<th>Description</th>
							<th>Category</th>
							<th class="right">Amount</th>
							<th class="right">Balance</th>
						</tr>
					</thead>
					<tbody>
						{#each filtered as t (t.id)}
							<tr>
								<td class="muted">{t.gameDate ? t.gameDate.slice(0, 10) : '—'}</td>
								<td>{t.description ?? t.transactionType}</td>
								<td><AppBadge label={t.ifrsCategory ?? 'other'} tone={tone(t)} /></td>
								<td
									class="right tnum"
									style="color: {tone(t) === 'success'
										? 'var(--color-success)'
										: 'var(--color-error)'};"
								>
									{tone(t) === 'success' ? '+' : '-'}{money(Math.abs(t.amount))}
								</td>
								<td class="right tnum muted">{money(t.balanceAfter)}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</CraftCard>
</div>

<style>
	.ledger {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
	}
	.filters {
		display: flex;
		gap: var(--space-xs);
		flex-wrap: wrap;
	}
	.filters button {
		padding: var(--space-xs) var(--space-sm);
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		color: var(--color-text-secondary);
		font-size: 11px;
		cursor: pointer;
	}
	.filters button.active {
		background: var(--color-accent-subtle);
		border-color: var(--color-accent);
		color: var(--color-accent);
	}
	.table-wrap {
		overflow-x: auto;
	}
	table {
		width: 100%;
		border-collapse: collapse;
		font-size: 13px;
	}
	th {
		text-align: left;
		padding: var(--space-sm);
		color: var(--color-text-secondary);
		font-size: 10px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		border-bottom: 1px solid var(--color-border);
	}
	td {
		padding: var(--space-sm);
		border-bottom: 0.5px solid var(--color-border-subtle);
	}
	.right {
		text-align: right;
	}
	.muted {
		color: var(--color-text-muted);
		font-size: 12px;
	}
</style>
