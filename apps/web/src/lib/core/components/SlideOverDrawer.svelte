<script lang="ts">
	import type { Snippet } from 'svelte';
	import TactileButton from './TactileButton.svelte';

	/**
	 * Right slide-over inspector drawer for deep operational workflows. Ported
	 * from Flutter `SlideOverDrawer`. Keeps the dashboard context visible under
	 * a subtle scrim; Escape or scrim click closes it.
	 */
	type Props = {
		title: string;
		subtitle?: string;
		children: Snippet;
		bottomActions?: Snippet;
		width?: string;
		onclose: () => void;
	};

	let { title, subtitle, children, bottomActions, width = '460px', onclose }: Props = $props();

	function onKeydown(e: KeyboardEvent) {
		if (e.key === 'Escape') onclose();
	}
</script>

<svelte:window onkeydown={onKeydown} />

<div class="overlay">
	<button class="scrim" aria-label="Close drawer" onclick={onclose}></button>
	<div class="drawer" style="width: {width};" role="dialog" aria-modal="true" aria-label={title}>
		<header>
			<div class="titles">
				<span class="title">{title}</span>
				{#if subtitle}<span class="subtitle">{subtitle}</span>{/if}
			</div>
			<TactileButton text="ESC" type="ghost" height="28px" width="64px" onclick={onclose} />
		</header>
		<div class="body">{@render children()}</div>
		{#if bottomActions}
			<footer>{@render bottomActions()}</footer>
		{/if}
	</div>
</div>

<style>
	.overlay {
		position: fixed;
		inset: 0;
		z-index: 150;
		display: flex;
		justify-content: flex-end;
	}
	.scrim {
		position: absolute;
		inset: 0;
		background: rgb(0 0 0 / 0.45);
		border: none;
		cursor: default;
	}
	.drawer {
		position: relative;
		height: 100%;
		background: var(--color-surface-3);
		border-left: 1px solid var(--color-border-highlight);
		display: flex;
		flex-direction: column;
		max-width: 100vw;
	}
	header {
		height: 48px;
		flex: 0 0 auto;
		display: flex;
		align-items: center;
		gap: var(--space-md);
		padding: 0 var(--space-lg);
		background: var(--color-surface-2);
		border-bottom: 1px solid var(--color-border-subtle);
	}
	.titles {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
	}
	.title {
		font-size: 15px;
		font-weight: 600;
		letter-spacing: 0.04em;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.subtitle {
		font-size: 11px;
		color: var(--color-text-muted);
		letter-spacing: 0.12em;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.body {
		flex: 1 1 auto;
		overflow-y: auto;
		padding: var(--space-lg);
	}
	footer {
		flex: 0 0 auto;
		padding: var(--space-md);
		background: var(--color-surface-2);
		border-top: 1px solid var(--color-border-subtle);
	}
	@media (prefers-reduced-motion: no-preference) {
		.drawer {
			animation: slide-in var(--motion-base) var(--motion-ease-out);
		}
	}
	@keyframes slide-in {
		from {
			transform: translateX(100%);
		}
		to {
			transform: none;
		}
	}
</style>
