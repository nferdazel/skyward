<script lang="ts">
	/**
	 * Lightweight line chart with a vertical gradient fill and optional min/max
	 * labels. Ported from Flutter `AppLineChart`.
	 */
	type Props = {
		values: number[];
		height?: number;
		color?: string;
		showMinMaxLabels?: boolean;
		formatLabel?: (v: number) => string;
	};

	let {
		values,
		height = 120,
		color = 'var(--color-accent)',
		showMinMaxLabels = false,
		formatLabel
	}: Props = $props();

	const W = 600;
	const PAD_X = 8;
	const PAD_Y = 10;

	const geom = $derived.by(() => {
		if (values.length < 2) return null;
		const min = Math.min(...values);
		const max = Math.max(...values);
		const span = max - min || 1;
		const px = (i: number) => PAD_X + (i / (values.length - 1)) * (W - PAD_X * 2);
		const py = (v: number) => height - PAD_Y - ((v - min) / span) * (height - PAD_Y * 2);
		const pts = values.map((v, i) => [px(i), py(v)] as const);
		const line = pts.map(([x, y]) => `${x.toFixed(1)},${y.toFixed(1)}`).join(' ');
		const area = `${PAD_X},${height - PAD_Y} ${line} ${W - PAD_X},${height - PAD_Y}`;
		return { line, area, min, max };
	});

	const label = (v: number) => (formatLabel ? formatLabel(v) : String(Math.round(v)));
	const uid = `lc-${Math.random().toString(36).slice(2, 8)}`;
</script>

{#if geom}
	<div class="chart" style="height: {height}px;">
		{#if showMinMaxLabels}
			<div class="labels">
				<span>{label(geom.max)}</span>
				<span>{label(geom.min)}</span>
			</div>
		{/if}
		<svg
			viewBox="0 0 {W} {height}"
			preserveAspectRatio="none"
			role="img"
			aria-label="Line chart showing trend over {values.length} periods"
		>
			<defs>
				<linearGradient id={uid} x1="0" y1="0" x2="0" y2="1">
					<stop offset="0%" stop-color={color} stop-opacity="0.28" />
					<stop offset="100%" stop-color={color} stop-opacity="0" />
				</linearGradient>
			</defs>
			<polygon points={geom.area} fill="url(#{uid})" />
			<polyline
				points={geom.line}
				fill="none"
				stroke={color}
				stroke-width="2"
				stroke-linejoin="round"
				vector-effect="non-scaling-stroke"
			/>
		</svg>
	</div>
{/if}

<style>
	.chart {
		position: relative;
		width: 100%;
	}
	svg {
		width: 100%;
		height: 100%;
		display: block;
	}
	.labels {
		position: absolute;
		inset: 0;
		display: flex;
		flex-direction: column;
		justify-content: space-between;
		font-size: 10px;
		color: var(--color-text-muted);
		pointer-events: none;
	}
</style>
