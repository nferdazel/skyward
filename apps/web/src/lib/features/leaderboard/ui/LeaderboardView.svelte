<script lang="ts">
	import CraftCard from '$lib/core/components/CraftCard.svelte';
	import AppBadge from '$lib/core/components/AppBadge.svelte';
	import SegmentedPillControl from '$lib/core/components/SegmentedPillControl.svelte';
	import type { LeaderboardStore } from '../state/leaderboard-store.svelte';
	import type { LeaderboardEntry } from '../domain/leaderboard-models';
	import { colors } from '$lib/core/theme/tokens';

	/**
	 * Leaderboard view. Ported from Flutter `LeaderboardView`: sort toggle, a
	 * master rankings table, and a desktop competitor-intel panel.
	 */
	type Props = { store: LeaderboardStore; currentUserId?: string };
	let { store, currentUserId }: Props = $props();

	type SortKey = 'net_worth' | 'fleet_size' | 'monthly_revenue';
	let sort = $state<SortKey>('net_worth');
	let selectedId = $state<string | null>(null);

	const fmt = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${fmt.format(Math.round(n))}`;

	const sorted = $derived(
		[...store.state.entries].sort((a, b) => {
			if (sort === 'fleet_size') return b.fleetSize - a.fleetSize;
			if (sort === 'monthly_revenue') return b.monthlyRevenue - a.monthlyRevenue;
			return b.netWorth - a.netWorth;
		})
	);

	const leader = $derived(sorted[0] ?? null);
	const selected = $derived(sorted.find((e) => e.id === selectedId) ?? null);
	const insights = $derived(store.state.insights);
	const gap = $derived(
		leader && selected && leader.id !== selected.id ? leader.netWorth - selected.netWorth : null
	);

	async function pick(entry: LeaderboardEntry) {
		selectedId = entry.id;
		await store.loadCompetitor(entry.id, entry.isBot);
	}

	function statusTone(status: string): 'success' | 'warning' | 'error' | 'secondary' {
		const s = status.toLowerCase();
		if (s === 'active') return 'success';
		if (s === 'distress') return 'error';
		if (s === 'recovery' || s === 'maintenance') return 'warning';
		return 'secondary';
	}
</script>

<section>
	<div class="head">
		<h2>Leaderboard</h2>
		<SegmentedPillControl
			items={[
				{ value: 'net_worth', label: 'Net worth' },
				{ value: 'fleet_size', label: 'Fleet' },
				{ value: 'monthly_revenue', label: 'Revenue' }
			]}
			selected={sort}
			onselect={(v) => (sort = v as SortKey)}
		/>
	</div>

	{#if store.state.error}
		<p class="err" role="alert">{store.state.error}</p>
	{/if}

	{#if sorted.length === 0 && !store.state.loading}
		<CraftCard><p class="muted">No rankings yet.</p></CraftCard>
	{:else}
		<div class="md">
			<div class="master">
				<table>
					<thead>
						<tr>
							<th>#</th>
							<th>Company</th>
							<th class="right">Cash</th>
							<th class="right">Net worth</th>
							<th class="right">Fleet</th>
							<th class="right">Revenue/mo</th>
						</tr>
					</thead>
					<tbody>
						{#each sorted as entry, i (entry.id)}
							{@const isHuman = !entry.isBot}
							<tr
								class:selected={entry.id === selectedId}
								class:self={entry.id === currentUserId}
								onclick={() => pick(entry)}
							>
								<td>
									<span class="rank" class:human={isHuman}>{i + 1}</span>
								</td>
								<td>
									<span class="company">{entry.companyName}</span>
									{#if entry.isBot}<AppBadge label="AI" tone="secondary" />{/if}
									{#if entry.id === currentUserId}<AppBadge label="you" tone="primary" />{/if}
								</td>
								<td class="right tnum">{money(entry.cash)}</td>
								<td class="right tnum">{money(entry.netWorth)}</td>
								<td class="right tnum">{entry.fleetSize}</td>
								<td class="right tnum">{money(entry.monthlyRevenue)}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>

			<aside class="detail">
				{#if !selected}
					<CraftCard><p class="muted">Select a competitor to see intel.</p></CraftCard>
				{:else}
					{@const entry = selected}
					<CraftCard>
						<div class="intel">
							<div class="row-between">
								<span class="title">{entry.companyName.toUpperCase()}</span>
								<AppBadge label={entry.status} tone={statusTone(entry.status)} />
							</div>
							<span class="muted">CEO: {entry.ceoName}</span>

							{#if insights}
								<dl>
									<div>
										<dt>Cash</dt>
										<dd class="tnum">{money(insights.cash)}</dd>
									</div>
									<div>
										<dt>Net worth</dt>
										<dd class="tnum">{money(insights.netWorth)}</dd>
									</div>
									<div>
										<dt>Fleet</dt>
										<dd class="tnum">{insights.fleetSize}</dd>
									</div>
									<div>
										<dt>Revenue/mo</dt>
										<dd class="tnum">{money(insights.monthlyRevenue)}</dd>
									</div>
								</dl>

								{#if gap !== null}
									<div class="gap">
										<span class="k">Gap to leader</span>
										<span
											class="gap-val tnum"
											style="color: {gap > 0 ? colors.warning : colors.success};"
										>
											{gap > 0 ? money(gap) : 'World leader'}
										</span>
									</div>
								{/if}

								{#if Object.keys(insights.fleetBreakdown).length > 0}
									<div class="breakdown">
										<span class="k">Fleet breakdown</span>
										{#each Object.entries(insights.fleetBreakdown) as [model, count] (model)}
											<div class="bd-row">
												<span>{model}</span><span class="tnum">{count}</span>
											</div>
										{/each}
									</div>
								{/if}

								{#if insights.networkRoutes.length > 0}
									<div class="routes">
										<span class="k">Network</span>
										<div class="chips">
											{#each insights.networkRoutes.slice(0, 12) as r (r)}
												<span class="chip">{r}</span>
											{/each}
										</div>
									</div>
								{/if}
							{:else}
								<p class="muted">Loading intel…</p>
							{/if}
						</div>
					</CraftCard>
				{/if}
			</aside>
		</div>
	{/if}
</section>

<style>
	section {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
	}
	.head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: var(--space-md);
		flex-wrap: wrap;
	}
	h2 {
		margin: 0;
		font-size: 16px;
		letter-spacing: 0.06em;
		text-transform: uppercase;
	}
	.md {
		display: flex;
		gap: var(--space-md);
		align-items: flex-start;
	}
	.master {
		flex: 68;
		min-width: 0;
		overflow-x: auto;
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
	}
	.detail {
		flex: 32;
		min-width: 0;
	}
	table {
		width: 100%;
		border-collapse: collapse;
		font-size: 13px;
	}
	th {
		text-align: left;
		padding: var(--space-sm);
		background: var(--color-surface-2);
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
	tbody tr {
		cursor: pointer;
	}
	tbody tr:hover td {
		background: rgb(36 46 61 / 0.4);
	}
	tbody tr.selected td {
		background: var(--color-surface-active);
	}
	tbody tr.self td {
		box-shadow: inset 2px 0 0 var(--color-accent);
	}
	.rank {
		display: inline-grid;
		place-items: center;
		width: 22px;
		height: 22px;
		border-radius: 50%;
		background: rgb(117 132 137 / 0.15);
		color: var(--color-text-secondary);
		font-size: 11px;
		font-weight: 600;
	}
	.rank.human {
		background: var(--color-accent-subtle);
		color: var(--color-accent);
	}
	.company {
		margin-right: var(--space-xs);
	}
	.intel {
		display: flex;
		flex-direction: column;
		gap: var(--space-sm);
	}
	.row-between {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: var(--space-sm);
	}
	.title {
		font-weight: 700;
		letter-spacing: 0.04em;
	}
	.k {
		font-size: 10px;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: var(--color-text-muted);
	}
	.muted {
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	dl {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin: var(--space-sm) 0;
	}
	dl > div {
		display: flex;
		justify-content: space-between;
	}
	dt {
		color: var(--color-text-muted);
		font-size: 11px;
	}
	dd {
		margin: 0;
		font-size: 13px;
	}
	.gap {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		padding-top: var(--space-sm);
		border-top: 1px solid var(--color-border-subtle);
	}
	.gap-val {
		font-size: 16px;
		font-weight: 700;
	}
	.breakdown,
	.routes {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		padding-top: var(--space-sm);
		border-top: 1px solid var(--color-border-subtle);
	}
	.bd-row {
		display: flex;
		justify-content: space-between;
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.chips {
		display: flex;
		flex-wrap: wrap;
		gap: var(--space-xs);
	}
	.chip {
		font-size: 10px;
		padding: 1px 5px;
		border-radius: var(--radius-tight);
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		color: var(--color-text-secondary);
	}
	.err {
		color: var(--color-error);
		font-size: 13px;
	}
	@media (max-width: 1050px) {
		.detail {
			display: none;
		}
	}
</style>
