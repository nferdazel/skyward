<script lang="ts">
	import AppCard from '$lib/core/components/AppCard.svelte';
	import AppButton from '$lib/core/components/AppButton.svelte';
	import AppBadge from '$lib/core/components/AppBadge.svelte';
	import AppEmptyState from '$lib/core/components/AppEmptyState.svelte';
	import AppDialogShell from '$lib/core/components/AppDialogShell.svelte';
	import type { LeaderboardStore } from '../state/leaderboard-store.svelte';
	import type { LeaderboardEntry } from '../domain/leaderboard-models';

	type Props = { store: LeaderboardStore };
	let { store }: Props = $props();

	let selected = $state<LeaderboardEntry | null>(null);

	const num = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${num.format(Math.round(n))}`;

	async function openInsights(entry: LeaderboardEntry) {
		selected = entry;
		await store.loadCompetitor(entry.id, entry.isBot);
	}
</script>

<section>
	<div class="head">
		<h2>Leaderboard</h2>
		<AppButton text="Reload" variant="secondary" onclick={() => store.load()} />
	</div>

	{#if store.state.error}
		<p class="error" role="alert">{store.state.error}</p>
	{/if}

	<AppCard>
		{#if store.state.entries.length === 0 && !store.state.loading}
			<AppEmptyState title="No rankings" description="No leaderboard data yet." />
		{:else}
			<div class="table-wrap">
				<table>
					<thead>
						<tr>
							<th>#</th>
							<th>Airline</th>
							<th>CEO</th>
							<th>Net worth</th>
							<th>Fleet</th>
							<th>Status</th>
							<th></th>
						</tr>
					</thead>
					<tbody>
						{#each store.state.entries as entry, i (entry.id)}
							<tr>
								<td>{i + 1}</td>
								<td>
									{entry.companyName}
									{#if entry.isBot}<AppBadge label="AI" tone="secondary" />{/if}
								</td>
								<td>{entry.ceoName}</td>
								<td>{money(entry.netWorth)}</td>
								<td>{entry.fleetSize}</td>
								<td>{entry.status}</td>
								<td>
									<AppButton
										text="Details"
										variant="secondary"
										onclick={() => openInsights(entry)}
									/>
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</AppCard>
</section>

{#if selected && store.state.insights}
	{@const ins = store.state.insights}
	<AppDialogShell
		title="Competitor details"
		subtitle={ins.companyName}
		onclose={() => (selected = null)}
	>
		{#snippet children()}
			<dl>
				<div>
					<dt>CEO</dt>
					<dd>{ins.ceoName}</dd>
				</div>
				<div>
					<dt>Cash</dt>
					<dd>{money(ins.cash)}</dd>
				</div>
				<div>
					<dt>Net worth</dt>
					<dd>{money(ins.netWorth)}</dd>
				</div>
				<div>
					<dt>Fleet</dt>
					<dd>{ins.fleetSize}</dd>
				</div>
				<div>
					<dt>Revenue/mo</dt>
					<dd>{money(ins.monthlyRevenue)}</dd>
				</div>
				<div>
					<dt>Status</dt>
					<dd>{ins.status}</dd>
				</div>
			</dl>
			{#if ins.networkRoutes.length > 0}
				<p class="sub">Routes: {ins.networkRoutes.join(', ')}</p>
			{/if}
		{/snippet}
		{#snippet actions()}
			<AppButton text="Tutup" variant="secondary" onclick={() => (selected = null)} />
		{/snippet}
	</AppDialogShell>
{/if}

<style>
	.head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: var(--space-md);
	}
	h2 {
		margin: 0;
		font-size: 16px;
		letter-spacing: 0.06em;
		text-transform: uppercase;
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
		font-size: 11px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		border-bottom: 0.5px solid var(--color-border);
	}
	td {
		padding: var(--space-sm);
		border-bottom: 0.5px solid var(--color-border-subtle);
	}
	dl {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin: 0;
	}
	dl > div {
		display: flex;
		justify-content: space-between;
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
	.sub {
		color: var(--color-text-secondary);
		font-size: 13px;
	}
	.error {
		color: var(--color-error);
		font-size: 13px;
	}
</style>
