<script lang="ts">
	import type { Snippet } from 'svelte';

	/**
	 * Pressable button, primary/secondary, with optional loading state and icon.
	 * Ported from Flutter `AppButton`. Icon is a snippet so callers pass any SVG.
	 */
	type Props = {
		text: string;
		onclick?: () => void;
		loading?: boolean;
		variant?: 'primary' | 'secondary';
		icon?: Snippet;
		width?: string;
		height?: string;
		type?: 'button' | 'submit';
	};

	let {
		text,
		onclick,
		loading = false,
		variant = 'primary',
		icon,
		width,
		height = '40px',
		type = 'button'
	}: Props = $props();

	const disabled = $derived(onclick === undefined || loading);
</script>

<button
	{type}
	class="app-button {variant}"
	style="width: {width ?? 'auto'}; height: {height};"
	{disabled}
	aria-busy={loading}
	onclick={disabled ? undefined : onclick}
>
	{#if loading}
		<span class="spinner" aria-hidden="true"></span>
	{:else}
		{#if icon}
			<span class="icon">{@render icon()}</span>
		{/if}
		<span class="label">{text}</span>
	{/if}
</button>

<style>
	.app-button {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: var(--space-sm);
		padding: 0 var(--space-md);
		border-radius: var(--radius-default);
		border: none;
		font-family: var(--font-sans);
		font-size: 12px;
		font-weight: 600;
		letter-spacing: 0.06em;
		cursor: pointer;
		overflow: hidden;
		transition:
			background var(--motion-fast) var(--motion-ease),
			color var(--motion-fast) var(--motion-ease);
	}

	.app-button:disabled {
		cursor: not-allowed;
	}

	.primary {
		background: var(--color-accent);
		color: #000;
	}
	.primary:disabled {
		background: var(--color-border);
		color: var(--color-text-muted);
	}
	.primary:not(:disabled):hover {
		background: var(--color-accent-bright);
	}

	.secondary {
		background: transparent;
		color: var(--color-accent);
		border: 1px solid var(--color-accent);
	}
	.secondary:disabled {
		border-color: var(--color-border);
		color: var(--color-text-muted);
	}
	.secondary:not(:disabled):hover {
		background: var(--color-accent-ghost);
	}

	.icon {
		display: inline-flex;
	}
	.label {
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.spinner {
		width: 16px;
		height: 16px;
		border: 2px solid currentColor;
		border-top-color: transparent;
		border-radius: 50%;
		animation: spin 0.7s linear infinite;
	}

	@keyframes spin {
		to {
			transform: rotate(360deg);
		}
	}

	@media (prefers-reduced-motion: reduce) {
		.spinner {
			animation-duration: 2s;
		}
	}
</style>
