<script lang="ts">
	/**
	 * Skyward brand logo — radar rings + aircraft silhouette, matching the
	 * favicon and Flutter `SkywardLogo`.
	 */
	type Props = { size?: number; showBackground?: boolean };
	let { size = 32, showBackground = true }: Props = $props();
</script>

<svg
	width={size}
	height={size}
	viewBox="0 0 48 48"
	role="img"
	aria-label="Skyward"
	xmlns="http://www.w3.org/2000/svg"
>
	{#if showBackground}
		<rect x="0" y="0" width="48" height="48" rx="6" fill="var(--color-surface)" />
	{/if}
	<!-- radar rings -->
	<circle
		cx="24"
		cy="24"
		r="19.2"
		fill="none"
		stroke="var(--color-accent)"
		stroke-opacity="0.2"
		stroke-width="0.72"
	/>
	<circle
		cx="24"
		cy="24"
		r="14.4"
		fill="none"
		stroke="var(--color-accent)"
		stroke-opacity="0.12"
		stroke-width="0.72"
	/>
	<!-- aircraft silhouette -->
	<path
		d="M24 8 L26 20 L40 26 L26 28 L23 40 L21 28 L8 26 L22 20 Z"
		fill="var(--color-accent)"
		fill-opacity="0.9"
	/>
	<circle cx="24" cy="40" r="1.6" fill="var(--color-teal)" />
</svg>
