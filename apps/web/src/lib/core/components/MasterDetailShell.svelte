<script lang="ts">
	import type { Snippet } from 'svelte';

	/**
	 * Shadowless, responsive master-detail container. Ported from Flutter
	 * `MasterDetailShell`.
	 *
	 * Wide viewports (>= breakpoint) with a visible detail show a split view
	 * separated by a 1px structural border; otherwise only the master renders.
	 */
	type Props = {
		master: Snippet;
		detail?: Snippet;
		masterFlex?: number;
		detailFlex?: number;
		isDetailVisible?: boolean;
		breakpoint?: number;
	};

	let {
		master,
		detail,
		masterFlex = 7,
		detailFlex = 3,
		isDetailVisible = true,
		breakpoint = 1050
	}: Props = $props();
</script>

<div
	class="md"
	style="--breakpoint: {breakpoint}px; --master-flex: {masterFlex}; --detail-flex: {detailFlex};"
>
	<div class="master">{@render master()}</div>
	{#if detail && isDetailVisible}
		<div class="divider" aria-hidden="true"></div>
		<div class="detail">{@render detail()}</div>
	{/if}
</div>

<style>
	.md {
		display: flex;
		align-items: stretch;
		height: 100%;
		min-height: 0;
	}
	.master {
		flex: var(--master-flex);
		min-width: 0;
		overflow: auto;
	}
	.divider {
		width: 1px;
		background: var(--color-border);
		flex: 0 0 auto;
	}
	.detail {
		flex: var(--detail-flex);
		min-width: 0;
		overflow: auto;
		background: var(--color-surface);
	}

	/* Below the breakpoint the detail is hidden (master only). */
	@media (max-width: 1050px) {
		.divider,
		.detail {
			display: none;
		}
	}
</style>
