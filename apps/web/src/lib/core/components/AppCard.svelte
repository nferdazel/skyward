<script lang="ts">
	import type { Snippet } from 'svelte';

	/**
	 * Bordered surface card with optional header. Ported from Flutter `AppCard`.
	 * `panel` variant is edge-to-edge (1px border, no radius) for form sections.
	 */
	type Props = {
		children: Snippet;
		header?: Snippet;
		variant?: 'default' | 'panel';
	};

	let { children, header, variant = 'default' }: Props = $props();
</script>

<div class="app-card {variant}">
	{#if header}
		<div class="card-header">{@render header()}</div>
	{/if}
	<div class="card-body">{@render children()}</div>
</div>

<style>
	.app-card {
		background: var(--color-surface);
		border: 0.5px solid var(--color-border);
		border-radius: var(--radius-default);
		display: flex;
		flex-direction: column;
		min-width: 0;
	}

	.app-card.panel {
		border: 1px solid var(--color-border);
		border-radius: 0;
	}

	.card-header {
		height: var(--space-xxxl);
		display: flex;
		align-items: center;
		padding: 0 var(--space-card);
		background: var(--color-surface-2);
		border-bottom: 0.5px solid var(--color-border);
	}

	.card-body {
		padding: var(--space-card);
		flex: 1 1 auto;
		min-height: 0;
	}
</style>
