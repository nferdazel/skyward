<script lang="ts">
	import type { Snippet } from 'svelte';
	import AppSparkline from './AppSparkline.svelte';
	import { colors } from '$lib/core/theme/tokens';

	type Status = 'nominal' | 'caution' | 'critical' | 'standby';
	type DeltaType = 'positive' | 'negative' | 'neutral';

	type Props = {
		label: string;
		value: string | number;
		unit?: string;
		delta?: number | string;
		deltaType?: DeltaType;
		deltaPeriod?: string;
		sparklineValues?: number[];
		sparklineColor?: string;
		status?: Status;
		statusLabel?: string;
		badge?: string;
		subtext?: string;
		icon?: Snippet;
		onclick?: () => void;
	};

	let {
		label,
		value,
		unit,
		delta,
		deltaType,
		deltaPeriod = '30d',
		sparklineValues,
		sparklineColor,
		status = 'nominal',
		statusLabel,
		badge,
		subtext,
		icon,
		onclick
	}: Props = $props();

	let pressed = $state(false);

	const computedDeltaType = $derived.by<DeltaType>(() => {
		if (deltaType) return deltaType;
		if (typeof delta === 'number') {
			if (delta > 0) return 'positive';
			if (delta < 0) return 'negative';
			return 'neutral';
		}
		if (typeof delta === 'string') {
			if (delta.startsWith('+')) return 'positive';
			if (delta.startsWith('-')) return 'negative';
		}
		return 'neutral';
	});

	const formattedDelta = $derived.by(() => {
		if (delta === undefined || delta === null) return null;
		if (typeof delta === 'number') {
			const sign = delta > 0 ? '+' : '';
			return `${sign}${delta}%`;
		}
		return delta;
	});

	const statusToneColor = $derived.by(() => {
		switch (status) {
			case 'nominal':
				return colors.success;
			case 'caution':
				return colors.warning;
			case 'critical':
				return colors.error;
			case 'standby':
			default:
				return colors.textSecondary;
		}
	});

	const effectiveSparklineColor = $derived(
		sparklineColor ??
			(computedDeltaType === 'positive'
				? colors.success
				: computedDeltaType === 'negative'
					? colors.error
					: colors.accent)
	);
</script>

<!-- svelte-ignore a11y_no_noninteractive_tabindex -->
<div
	class="telemetry-card"
	class:interactive={onclick !== undefined}
	class:pressed
	role={onclick ? 'button' : 'region'}
	tabindex={onclick ? 0 : undefined}
	aria-label="{label}: {value}{unit ? ' ' + unit : ''}"
	{onclick}
	onkeydown={(e) => {
		if (onclick && (e.key === 'Enter' || e.key === ' ')) {
			e.preventDefault();
			onclick();
		}
	}}
	onpointerdown={() => onclick && (pressed = true)}
	onpointerup={() => (pressed = false)}
	onpointerleave={() => (pressed = false)}
>
	<!-- Top Highlight 1px Bevel -->
	<span class="top-bevel" aria-hidden="true"></span>

	<!-- Header cluster -->
	<div class="card-header">
		<div class="header-left">
			{#if status}
				<span
					class="status-dot"
					style="color: {statusToneColor};"
					title="Status: {statusLabel ?? status.toUpperCase()}"
					aria-hidden="true"
				></span>
			{/if}
			<span class="label micro-label">{label}</span>
		</div>
		<div class="header-right">
			{#if badge}
				<span class="telemetry-badge mono">{badge}</span>
			{/if}
			{#if icon}
				<span class="icon-slot">{@render icon()}</span>
			{/if}
		</div>
	</div>

	<!-- Primary KPI Metric -->
	<div class="value-block">
		<span class="value kpi-large tnum">{value}</span>
		{#if unit}
			<span class="unit mono">{unit}</span>
		{/if}
	</div>

	<!-- Sparkline + Delta Row -->
	<div class="card-footer">
		<div class="trend-zone">
			{#if sparklineValues && sparklineValues.length >= 2}
				<AppSparkline
					values={sparklineValues}
					width={84}
					height={24}
					color={effectiveSparklineColor}
				/>
			{/if}
		</div>

		<div class="delta-zone">
			{#if formattedDelta}
				<div class="delta-pill {computedDeltaType} mono tnum">
					<span class="arrow" aria-hidden="true">
						{computedDeltaType === 'positive' ? '▲' : computedDeltaType === 'negative' ? '▼' : '■'}
					</span>
					<span>{formattedDelta}</span>
				</div>
				{#if deltaPeriod}
					<span class="delta-period">{deltaPeriod}</span>
				{/if}
			{:else if subtext}
				<span class="subtext">{subtext}</span>
			{/if}
		</div>
	</div>
</div>

<style>
	.telemetry-card {
		position: relative;
		display: flex;
		flex-direction: column;
		justify-content: space-between;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		padding: var(--space-card);
		min-width: 140px;
		color: var(--color-text-primary);
		overflow: hidden;
		transition:
			background var(--motion-fast) var(--motion-ease),
			border-color var(--motion-fast) var(--motion-ease),
			transform var(--motion-fast) var(--motion-ease-out);
	}

	.top-bevel {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		height: 1px;
		background: var(--color-border-highlight);
	}

	.telemetry-card.interactive {
		cursor: pointer;
	}

	.telemetry-card.interactive:hover {
		background: var(--color-surface-2);
		border-color: var(--color-border-highlight);
	}

	.telemetry-card.pressed {
		transform: scale(var(--press-scale));
	}

	.card-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: var(--space-xs);
	}

	.header-left {
		display: flex;
		align-items: center;
		gap: 6px;
	}

	.status-dot {
		width: 6px;
		height: 6px;
		border-radius: 50%;
		background-color: currentColor;
		box-shadow: 0 0 6px currentColor;
		animation: radar-pulse 1.4s infinite;
	}

	.label {
		color: var(--color-text-secondary);
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.header-right {
		display: flex;
		align-items: center;
		gap: 4px;
	}

	.telemetry-badge {
		font-size: 10px;
		color: var(--color-accent);
		background: var(--color-accent-subtle);
		padding: 1px 4px;
		border-radius: var(--radius-tight);
	}

	.icon-slot {
		display: flex;
		color: var(--color-text-muted);
	}

	.value-block {
		display: flex;
		align-items: baseline;
		gap: 4px;
		margin: var(--space-xs) 0;
	}

	.value {
		color: var(--color-text-primary);
		line-height: 1.1;
	}

	.unit {
		font-size: 11px;
		color: var(--color-text-muted);
	}

	.card-footer {
		display: flex;
		align-items: flex-end;
		justify-content: space-between;
		gap: var(--space-xs);
		margin-top: auto;
	}

	.trend-zone {
		flex: 1;
		min-width: 0;
	}

	.delta-zone {
		display: flex;
		flex-direction: column;
		align-items: flex-end;
		gap: 2px;
	}

	.delta-pill {
		display: inline-flex;
		align-items: center;
		gap: 3px;
		font-size: 11px;
		font-weight: 600;
		padding: 1px 5px;
		border-radius: var(--radius-tight);
	}

	.delta-pill.positive {
		color: var(--color-success);
		background: var(--color-success-subtle);
	}

	.delta-pill.negative {
		color: var(--color-error);
		background: var(--color-error-subtle);
	}

	.delta-pill.neutral {
		color: var(--color-text-secondary);
		background: var(--color-surface-2);
	}

	.arrow {
		font-size: 8px;
	}

	.delta-period {
		font-size: 9px;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.04em;
	}

	.subtext {
		font-size: 10px;
		color: var(--color-text-muted);
	}

	@media (prefers-reduced-motion: reduce) {
		.status-dot {
			animation: none;
		}
		.telemetry-card {
			transition: none;
		}
	}
</style>
