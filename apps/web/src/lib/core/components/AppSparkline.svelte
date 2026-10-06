<script lang="ts">
	/**
	 * Shadowless high-contrast sparkline. Ported from Flutter `AppSparkline`.
	 * Renders an SVG polyline; hides itself when there are fewer than 2 points.
	 */
	type Props = {
		values: number[];
		width?: number;
		height?: number;
		color?: string;
	};

	let { values, width = 120, height = 32, color = 'var(--color-accent)' }: Props = $props();

	const points = $derived.by(() => {
		if (values.length < 2) return '';
		const min = Math.min(...values);
		const max = Math.max(...values);
		const span = max - min || 1;
		const pad = 2;
		return values
			.map((v, i) => {
				const x = (i / (values.length - 1)) * (width - pad * 2) + pad;
				const y = height - pad - ((v - min) / span) * (height - pad * 2);
				return `${x.toFixed(1)},${y.toFixed(1)}`;
			})
			.join(' ');
	});
</script>

{#if values.length >= 2}
	<svg
		{width}
		{height}
		viewBox="0 0 {width} {height}"
		role="img"
		aria-label="Trend chart showing {values.length} data points"
	>
		<polyline {points} fill="none" stroke={color} stroke-width="1.5" stroke-linejoin="round" />
	</svg>
{/if}

<style>
	svg {
		display: block;
		max-width: 100%;
	}
</style>
