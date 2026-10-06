<script lang="ts">
	import type { Snippet } from 'svelte';

	/** Standar dialog: judul, subjudul opsional, konten, aksi. Port `AppDialogShell`. */
	type Props = {
		title: string;
		subtitle?: string;
		children?: Snippet;
		actions?: Snippet;
		headerTrailing?: Snippet;
		maxWidth?: string;
		onclose: () => void;
	};

	let {
		title,
		subtitle,
		children,
		actions,
		headerTrailing,
		maxWidth = '460px',
		onclose
	}: Props = $props();

	function onKeydown(event: KeyboardEvent) {
		if (event.key === 'Escape') onclose();
	}
</script>

<svelte:window onkeydown={onKeydown} />

<div class="backdrop">
	<button class="scrim" aria-label="Close dialog" onclick={onclose}></button>
	<div
		class="dialog"
		role="dialog"
		aria-modal="true"
		aria-label={title}
		style="max-width: {maxWidth};"
	>
		<div class="head">
			<span class="title">{title.toUpperCase()}</span>
			{#if headerTrailing}
				{@render headerTrailing()}
			{/if}
		</div>
		{#if subtitle}
			<p class="subtitle">{subtitle}</p>
		{/if}
		<div class="content">{@render children?.()}</div>
		{#if actions}
			<div class="actions">{@render actions()}</div>
		{/if}
	</div>
</div>

<style>
	.backdrop {
		position: fixed;
		inset: 0;
		display: grid;
		place-items: center;
		padding: var(--space-xl);
		z-index: 100;
	}
	.scrim {
		position: absolute;
		inset: 0;
		background: rgb(0 0 0 / 0.55);
		border: none;
		cursor: default;
	}
	.dialog {
		position: relative;
		width: 100%;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-soft);
		padding: var(--space-xl);
		color: var(--color-text-primary);
		font-family: var(--font-sans);
	}
	.head {
		display: flex;
		align-items: flex-start;
		gap: var(--space-md);
	}
	.title {
		flex: 1;
		font-size: 12px;
		font-weight: 600;
		letter-spacing: 0.06em;
		color: var(--color-accent);
	}
	.subtitle {
		margin: var(--space-xs) 0 0;
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.content {
		margin-top: var(--space-lg);
		max-height: 60vh;
		overflow-y: auto;
	}
	.actions {
		margin-top: var(--space-xl);
		display: flex;
		justify-content: flex-end;
		gap: var(--space-sm);
	}
</style>
