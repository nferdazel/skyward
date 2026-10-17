<script lang="ts">
	import { colors } from '$lib/core/theme/tokens';

	export type ExpenseSegment = {
		label: string;
		amount: number;
		color?: string;
	};

	type Props = {
		fuel?: number;
		crew?: number;
		maintenance?: number;
		lease?: number;
		other?: number;
		segments?: ExpenseSegment[];
		height?: number;
		showLegend?: boolean;
	};

	let {
		fuel,
		crew,
		maintenance,
		lease,
		other = 0,
		segments: customSegments,
		height = 10,
		showLegend = true
	}: Props = $props();

	function money(n: number): string {
		const abs = Math.abs(n);
		if (abs >= 1_000_000_000) return `$${(n / 1_000_000_000).toFixed(2)}B`;
		if (abs >= 1_000_000) return `$${(n / 1_000_000).toFixed(2)}M`;
		if (abs >= 1_000) return `$${(n / 1_000).toFixed(1)}k`;
		return `$${Math.round(n).toLocaleString('en-US')}`;
	}

	const activeSegments = $derived.by(() => {
		if (customSegments && customSegments.length > 0) {
			return customSegments;
		}

		// Built-in standard operational expense distribution
		const f = fuel ?? 0;
		const c = crew ?? 0;
		const m = maintenance ?? 0;
		const l = lease ?? 0;
		const o = other ?? 0;

		const list: ExpenseSegment[] = [];
		if (f > 0) list.push({ label: 'Fuel', amount: f, color: colors.warning });
		if (c > 0) list.push({ label: 'Crew', amount: c, color: colors.accent });
		if (m > 0) list.push({ label: 'Maint', amount: m, color: colors.error });
		if (l > 0) list.push({ label: 'Lease', amount: l, color: colors.teal });
		if (o > 0) list.push({ label: 'Other', amount: o, color: colors.neutral });

		return list;
	});

	const total = $derived(
		Math.max(
			activeSegments.reduce((sum, s) => sum + s.amount, 0),
			0
		)
	);

	const segmentsWithPct = $derived(
		activeSegments.map((s) => ({
			...s,
			color: s.color ?? colors.accent,
			pct: total > 0 ? Math.round((s.amount / total) * 100) : 0
		}))
	);
</script>

<div class="breakdown-container">
	<div class="header">
		<span class="title micro-label">Cost Distribution</span>
		<span class="total mono tnum">{money(total)}</span>
	</div>

	<div
		class="track"
		style="height: {height}px;"
		role="progressbar"
		aria-valuenow={100}
		aria-label="Operating expense distribution"
	>
		{#if total === 0}
			<div class="empty-bar" title="No expense records"></div>
		{:else}
			{#each segmentsWithPct as s}
				{#if s.pct > 0}
					<div
						class="segment"
						style="width: {s.pct}%; background-color: {s.color};"
						title="{s.label}: {money(s.amount)} ({s.pct}%)"
					></div>
				{/if}
			{/each}
		{/if}
	</div>

	{#if showLegend && segmentsWithPct.length > 0}
		<div class="legend">
			{#each segmentsWithPct as s}
				<div class="legend-item">
					<span class="dot" style="background-color: {s.color};"></span>
					<span class="name">{s.label}</span>
					<span class="pct mono tnum">{s.pct}%</span>
					<span class="amt mono tnum">{money(s.amount)}</span>
				</div>
			{/each}
		</div>
	{/if}
</div>

<style>
	.breakdown-container {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		padding: var(--space-xs) 0;
	}

	.header {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.title {
		color: var(--color-text-secondary);
	}

	.total {
		font-size: 12px;
		font-weight: 700;
		color: var(--color-text-primary);
	}

	.track {
		display: flex;
		width: 100%;
		border-radius: var(--radius-tight);
		overflow: hidden;
		background: var(--color-surface-2);
		border: 1px solid var(--color-border-subtle);
		gap: 1px;
	}

	.empty-bar {
		width: 100%;
		height: 100%;
		background: var(--color-border-subtle);
	}

	.segment {
		height: 100%;
		transition: width var(--motion-base) var(--motion-ease-out);
	}

	.legend {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(130px, 1fr));
		gap: var(--space-xs) var(--space-md);
		padding-top: var(--space-xs);
	}

	.legend-item {
		display: flex;
		align-items: center;
		gap: 6px;
		font-size: 11px;
	}

	.dot {
		width: 6px;
		height: 6px;
		border-radius: var(--radius-tight);
		flex-shrink: 0;
	}

	.name {
		color: var(--color-text-secondary);
		letter-spacing: 0.04em;
	}

	.pct {
		color: var(--color-text-primary);
		font-weight: 600;
	}

	.amt {
		color: var(--color-text-muted);
		font-size: 10px;
		margin-left: auto;
	}
</style>
