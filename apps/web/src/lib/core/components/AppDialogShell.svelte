<script lang="ts">
	import type { Snippet } from 'svelte';
	import TactileButton from './TactileButton.svelte';

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
		<span class="top-bevel" aria-hidden="true"></span>
		<div class="head">
			<div class="title-block">
				<span class="title micro-label">{title.toUpperCase()}</span>
				{#if subtitle}
					<p class="subtitle">{subtitle}</p>
				{/if}
			</div>
			{#if headerTrailing}
				{@render headerTrailing()}
			{:else}
				<TactileButton text="ESC" type="ghost" height="26px" keyHint="⎋" onclick={onclose} />
			{/if}
		</div>
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
		background: rgb(0 0 0 / 0.6);
		backdrop-filter: blur(2px);
		border: none;
		cursor: default;
	}
	.dialog {
		position: relative;
		width: 100%;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-soft);
		box-shadow: 0 16px 40px rgba(0, 0, 0, 0.6);
		padding: var(--space-xl);
		color: var(--color-text-primary);
		font-family: var(--font-sans);
		overflow: hidden;
	}
	.top-bevel {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		height: 1px;
		background: var(--color-border-highlight);
	}
	.head {
		display: flex;
		align-items: flex-start;
		justify-content: space-between;
		gap: var(--space-md);
		padding-bottom: var(--space-sm);
		border-bottom: 1px solid var(--color-border-subtle);
	}
	.title-block {
		flex: 1;
		min-width: 0;
	}
	.title {
		color: var(--color-accent);
	}
	.subtitle {
		margin: var(--space-xs) 0 0;
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.content {
		margin-top: var(--space-lg);
		max-height: 65vh;
		overflow-y: auto;
	}
	.actions {
		margin-top: var(--space-xl);
		display: flex;
		justify-content: flex-end;
		gap: var(--space-sm);
	}
</style>
