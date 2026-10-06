<script lang="ts">
	import AppDialogShell from './AppDialogShell.svelte';
	import TactileButton from './TactileButton.svelte';
	import { colors } from '$lib/core/theme/tokens';

	/**
	 * "While you were away" digest. Ported from Flutter `WhileAwayDigest`: shown
	 * after returning when at least one game day elapsed, summarising the
	 * flights run and cash movement.
	 */
	type Props = {
		elapsedDays: number;
		flightsRun: number;
		revenue: number;
		expense: number;
		onclose: () => void;
	};
	let { elapsedDays, flightsRun, revenue, expense, onclose }: Props = $props();

	const fmt = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${fmt.format(Math.round(n))}`;
	const net = $derived(revenue - expense);
</script>

<AppDialogShell title="While you were away" {onclose}>
	{#snippet children()}
		<p class="elapsed">{elapsedDays.toFixed(1)} game days elapsed.</p>
		<dl>
			<div>
				<dt>Flights run</dt>
				<dd class="tnum">{flightsRun}</dd>
			</div>
			<div>
				<dt>Revenue</dt>
				<dd class="tnum" style="color: {colors.success};">{money(revenue)}</dd>
			</div>
			<div>
				<dt>Expenses</dt>
				<dd class="tnum" style="color: {colors.error};">{money(expense)}</dd>
			</div>
			<div>
				<dt>Net</dt>
				<dd class="tnum" style="color: {net >= 0 ? colors.success : colors.error};">
					{money(net)}
				</dd>
			</div>
		</dl>
	{/snippet}
	{#snippet actions()}
		<TactileButton text="Got it" type="primary" onclick={onclose} />
	{/snippet}
</AppDialogShell>

<style>
	.elapsed {
		margin: 0 0 var(--space-md);
		color: var(--color-text-secondary);
		font-size: 13px;
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
		border-bottom: 1px solid var(--color-border-subtle);
		padding-bottom: var(--space-xs);
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
		font-weight: 600;
	}
</style>
