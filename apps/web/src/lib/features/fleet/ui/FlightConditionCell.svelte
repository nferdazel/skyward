<script lang="ts">
	import { conditionColor } from '$lib/core/theme/tokens';

	/**
	 * Condition cell: a colour-coded bar plus the numeric percentage.
	 * Ported from the Flutter fleet table wear-condition cell.
	 */
	type Props = { condition: number };
	let { condition = 0 }: Props = $props();

	const pct = $derived(Math.max(0, Math.min(100, condition)));
	const color = $derived(conditionColor(condition));
</script>

<div class="cond" title="{Math.round(condition)}%">
	<span class="bar" aria-hidden="true"
		><span class="fill" style="width: {pct}%; background: {color};"></span></span
	>
	<span class="pct tnum" style="color: {color};">{Math.round(condition)}%</span>
</div>

<style>
	.cond {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
		min-width: 96px;
	}
	.bar {
		flex: 1;
		height: 6px;
		background: var(--color-surface-3);
		border-radius: var(--radius-tight);
		overflow: hidden;
	}
	.fill {
		display: block;
		height: 100%;
	}
	.pct {
		font-size: 12px;
		font-weight: 600;
		width: 38px;
		text-align: right;
	}
</style>
