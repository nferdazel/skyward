<script lang="ts">
	/**
	 * Status badge with semantic color coding. Ported from Flutter `AppBadge`.
	 * Colour encodes the semantic meaning; the label is uppercased for display.
	 */
	type Props = {
		label: string;
		tone?: 'primary' | 'success' | 'warning' | 'error' | 'secondary' | 'teal' | 'gold';
		showDot?: boolean;
		pulseDot?: boolean;
		mono?: boolean;
	};

	let {
		label,
		tone = 'secondary',
		showDot = false,
		pulseDot = false,
		mono = false
	}: Props = $props();
</script>

<span class="app-badge {tone}" role="status">
	{#if showDot || pulseDot}
		<span class="dot" class:radar-pulse={pulseDot} aria-hidden="true"></span>
	{/if}
	<span class="label" class:mono class:tnum={mono}>{label.toUpperCase()}</span>
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
		border: 1px solid transparent;
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

	.radar-pulse {
		animation: radar-pulse 1.4s infinite;
		box-shadow: 0 0 6px currentColor;
	}

	.primary {
		color: var(--color-accent);
		background: var(--color-accent-subtle);
		border-color: rgba(91, 158, 224, 0.2);
	}
	.success {
		color: var(--color-success);
		background: var(--color-success-subtle);
		border-color: rgba(52, 208, 123, 0.2);
	}
	.warning {
		color: var(--color-warning);
		background: var(--color-warning-subtle);
		border-color: rgba(230, 168, 23, 0.2);
	}
	.error {
		color: var(--color-error);
		background: var(--color-error-subtle);
		border-color: rgba(224, 85, 85, 0.2);
	}
	.secondary {
		color: var(--color-text-secondary);
		background: rgb(128 144 163 / 0.12);
		border-color: var(--color-border-subtle);
	}
	.teal {
		color: var(--color-teal);
		background: var(--color-teal-subtle);
		border-color: rgba(58, 175, 160, 0.2);
	}
	.gold {
		color: var(--color-gold);
		background: rgba(255, 215, 0, 0.1);
		border-color: rgba(255, 215, 0, 0.25);
	}

	@media (prefers-reduced-motion: reduce) {
		.radar-pulse {
			animation: none;
		}
	}
</style>
