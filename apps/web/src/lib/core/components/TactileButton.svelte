<script lang="ts">
	import type { Snippet } from 'svelte';

	/**
	 * Tactile button with spring micro-interactions. Ported from Flutter
	 * `TactileButton`.
	 *
	 * - press depth scaling (0.98) with snappy return
	 * - hover brightness/border transition
	 * - zero-layout-shift morph between idle / loading / success
	 */
	type Props = {
		text: string;
		onclick?: () => void;
		loading?: boolean;
		success?: boolean;
		type?: 'primary' | 'secondary' | 'destructive' | 'ghost';
		icon?: Snippet;
		width?: string;
		height?: string;
	};

	let {
		text,
		onclick,
		loading = false,
		success = false,
		type = 'primary',
		icon,
		width,
		height = '36px'
	}: Props = $props();

	let pressed = $state(false);
	const enabled = $derived(onclick !== undefined && !loading && !success);
</script>

<button
	class="tactile {type}"
	class:pressed
	style="width: {width ?? 'auto'}; height: {height};"
	disabled={!enabled}
	aria-busy={loading}
	onpointerdown={() => enabled && (pressed = true)}
	onpointerup={() => (pressed = false)}
	onpointerleave={() => (pressed = false)}
	onclick={enabled ? onclick : undefined}
>
	{#if loading}
		<span class="spinner" aria-hidden="true"></span>
	{:else if success}
		<span class="check" aria-hidden="true">✓</span>
		<span class="label">DONE</span>
	{:else}
		{#if icon}<span class="icon">{@render icon()}</span>{/if}
		<span class="label">{text}</span>
	{/if}
</button>

<style>
	.tactile {
		display: inline-flex;
		align-items: center;
		justify-content: center;
		gap: var(--space-sm);
		padding: 0 var(--space-md);
		border-radius: var(--radius-default);
		border: 1px solid transparent;
		font-family: var(--font-sans);
		font-size: 12px;
		font-weight: 600;
		letter-spacing: 0.08em;
		cursor: pointer;
		overflow: hidden;
		transition:
			background var(--motion-fast) var(--motion-ease),
			color var(--motion-fast) var(--motion-ease),
			border-color var(--motion-fast) var(--motion-ease),
			transform var(--motion-fast) var(--motion-ease-out);
	}
	.tactile.pressed {
		transform: scale(var(--press-scale));
	}
	.tactile:disabled {
		cursor: default;
		background: var(--color-border-subtle);
		color: var(--color-text-muted);
		border-color: var(--color-border-subtle);
	}
	.label {
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}
	.icon {
		display: inline-flex;
	}

	.primary {
		background: var(--color-accent);
		color: #000;
	}
	.primary:not(:disabled):hover {
		background: var(--color-accent-bright);
	}

	.secondary {
		background: var(--color-surface);
		color: var(--color-text-primary);
		border-color: var(--color-border);
	}
	.secondary:not(:disabled):hover {
		background: var(--color-surface-2);
		color: var(--color-accent);
		border-color: var(--color-border-highlight);
	}

	.destructive {
		background: var(--color-error-subtle);
		color: var(--color-error);
		border-color: rgb(224 85 85 / 0.4);
	}
	.destructive:not(:disabled):hover {
		background: var(--color-error);
		color: #fff;
	}

	.ghost {
		background: transparent;
		color: var(--color-text-secondary);
	}
	.ghost:not(:disabled):hover {
		background: var(--color-surface-active);
		color: var(--color-text-primary);
	}

	.check {
		color: var(--color-success);
		font-weight: 700;
	}
	.tactile.success .label {
		color: var(--color-success);
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
		.tactile {
			transition: none;
		}
		.spinner {
			animation-duration: 2s;
		}
	}
</style>
