<script lang="ts">
	import type { Snippet } from 'svelte';

	/**
	 * Shadowless, border-anchored surface card. Ported from Flutter `CraftCard`.
	 * Optional 1px top highlight bevel; interactive hover/press when `onclick`.
	 * Renders a real <button> when interactive for correct a11y/keys.
	 */
	type Props = {
		children: Snippet;
		header?: Snippet;
		headerAction?: Snippet;
		panel?: boolean;
		onclick?: () => void;
		/** Allow content (e.g. a dropdown) to overflow the card edges. */
		overflowVisible?: boolean;
	};

	let {
		children,
		header,
		headerAction,
		panel = false,
		onclick,
		overflowVisible = false
	}: Props = $props();
	let pressed = $state(false);

	const cls = $derived(
		[
			'craft',
			panel ? 'panel' : '',
			onclick ? 'interactive' : '',
			pressed ? 'pressed' : '',
			overflowVisible ? 'overflow-visible' : ''
		]
			.filter(Boolean)
			.join(' ')
	);
</script>

{#snippet body()}
	{#if !panel}<span class="bevel" aria-hidden="true"></span>{/if}
	{#if header}
		<div class="head">
			<div class="head-main">{@render header()}</div>
			{#if headerAction}{@render headerAction()}{/if}
		</div>
	{/if}
	<div class="body">{@render children()}</div>
{/snippet}

{#if onclick}
	<button
		class={cls}
		{onclick}
		onpointerdown={() => (pressed = true)}
		onpointerup={() => (pressed = false)}
		onpointerleave={() => (pressed = false)}
	>
		{@render body()}
	</button>
{:else}
	<div class={cls}>
		{@render body()}
	</div>
{/if}

<style>
	.craft {
		position: relative;
		display: block;
		width: 100%;
		text-align: left;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		padding: var(--space-card);
		overflow: hidden;
		color: inherit;
		font-family: inherit;
	}
	.craft.panel {
		border-radius: 0;
	}
	/* Let dropdowns/menus escape the card (e.g. the blueprint planner). */
	.craft.overflow-visible {
		overflow: visible;
	}
	.bevel {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		height: 1px;
		background: var(--color-border-highlight);
	}
	.craft.interactive {
		cursor: pointer;
		transition:
			background var(--motion-fast) var(--motion-ease),
			transform var(--motion-fast) var(--motion-ease-out);
	}
	.craft.interactive:hover {
		background: var(--color-surface-2);
	}
	.craft.pressed {
		transform: scale(var(--press-scale));
	}
	.head {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
		margin-bottom: var(--space-sm);
	}
	.head-main {
		flex: 1;
		min-width: 0;
	}
	.body {
		min-width: 0;
	}
</style>
