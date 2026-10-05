<script lang="ts">
	/**
	 * Shimmer-free loading placeholder. Ported from Flutter `SkeletonCard`.
	 * Height controls the body block; the header line stays fixed.
	 */
	type Props = {
		height?: string;
	};

	let { height = '80px' }: Props = $props();
</script>

<div class="skeleton-card" aria-hidden="true">
	<div class="line"></div>
	<div class="block" style="height: {height};"></div>
</div>

<style>
	.skeleton-card {
		background: var(--color-surface);
		border: 0.5px solid var(--color-border);
		border-radius: var(--radius-default);
		padding: var(--space-md);
		display: flex;
		flex-direction: column;
		gap: var(--space-sm);
	}

	.line {
		width: 120px;
		height: 10px;
		background: rgb(100 116 139 / 0.15);
		border-radius: var(--radius-tight);
	}

	.block {
		width: 100%;
		background: rgb(100 116 139 / 0.08);
		border-radius: var(--radius-tight);
	}
</style>
