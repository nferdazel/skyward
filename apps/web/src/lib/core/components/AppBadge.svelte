<script lang="ts">
	/**
	 * Status badge with semantic color coding. Ported from Flutter `AppBadge`.
	 * Colour encodes the semantic meaning; the label is uppercased for display.
	 */
	type Props = {
		label: string;
		tone?: 'primary' | 'success' | 'warning' | 'error' | 'secondary';
		showDot?: boolean;
	};

	let { label, tone = 'secondary', showDot = false }: Props = $props();
</script>

<span class="app-badge {tone}" role="status">
	{#if showDot}
		<span class="dot" aria-hidden="true"></span>
	{/if}
	<span class="label">{label.toUpperCase()}</span>
</span>

<style>
	.app-badge {
		display: inline-flex;
		align-items: center;
		gap: var(--space-xs);
		padding: var(--space-xs) var(--space-sm);
		border-radius: var(--radius-tight);
		font-family: var(--font-sans);
		font-size: 11px;
		font-weight: 600;
		letter-spacing: 0.08em;
		line-height: 1;
		max-width: 100%;
	}

	.label {
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.dot {
		width: 6px;
		height: 6px;
		border-radius: 50%;
		background: currentColor;
		flex: 0 0 auto;
	}

	.primary {
		color: var(--color-accent);
		background: var(--color-accent-subtle);
	}
	.success {
		color: var(--color-success);
		background: var(--color-success-subtle);
	}
	.warning {
		color: var(--color-warning);
		background: var(--color-warning-subtle);
	}
	.error {
		color: var(--color-error);
		background: var(--color-error-subtle);
	}
	.secondary {
		color: var(--color-text-secondary);
		background: rgb(128 144 163 / 0.12);
	}
</style>
