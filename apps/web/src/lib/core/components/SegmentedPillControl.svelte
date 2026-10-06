<script lang="ts">
	/**
	 * Compact segmented pill control with a sliding active indicator. Ported from
	 * Flutter `SegmentedPillControl`.
	 */
	type Item = { value: string; label: string; countBadge?: number };
	type Props = {
		items: Item[];
		selected: string;
		onselect: (value: string) => void;
	};

	let { items, selected, onselect }: Props = $props();
</script>

<div class="seg" role="tablist">
	{#each items as item (item.value)}
		<button
			role="tab"
			aria-selected={item.value === selected}
			class:active={item.value === selected}
			onclick={() => onselect(item.value)}
		>
			{item.label}
			{#if item.countBadge !== undefined}<span class="count">{item.countBadge}</span>{/if}
		</button>
	{/each}
</div>

<style>
	.seg {
		display: inline-flex;
		height: 34px;
		padding: 2px;
		gap: 2px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
	}
	button {
		display: inline-flex;
		align-items: center;
		gap: var(--space-xs);
		padding: 0 var(--space-md);
		background: transparent;
		border: none;
		border-radius: var(--radius-tight);
		color: var(--color-text-secondary);
		font-family: var(--font-sans);
		font-size: 11px;
		font-weight: 600;
		letter-spacing: 0.06em;
		text-transform: uppercase;
		cursor: pointer;
		transition:
			background var(--motion-fast) var(--motion-ease),
			color var(--motion-fast) var(--motion-ease);
	}
	button:hover {
		color: var(--color-text-primary);
	}
	button.active {
		background: var(--color-surface-active);
		color: var(--color-accent);
	}
	.count {
		min-width: 16px;
		padding: 0 4px;
		border-radius: 5px;
		background: var(--color-accent-subtle);
		color: var(--color-accent);
		font-size: 10px;
		font-variant-numeric: tabular-nums;
	}
</style>
