<script lang="ts">
	import type { RoutesStore } from '../state/routes-store.svelte';
	import type { UserRoute } from '../domain/route-models';
	import { colors } from '$lib/core/theme/tokens';

	/**
	 * Top-right overlay: a compact health monitor for the route network.
	 * Ported from the Flutter `_buildSystemMonitor`.
	 */
	type Props = { store: RoutesStore; routes: UserRoute[] };
	let { store, routes }: Props = $props();

	const money = (n: number) => `$${Math.round(n).toLocaleString('en-US')}`;

	const totalWeekly = $derived(
		routes.reduce((s, r) => {
			const a = store.state.assessments[r.id];
			return s + (a?.weeklyContribution ?? 0);
		}, 0)
	);
	const weak = $derived(
		routes.filter((r) => {
			const a = store.state.assessments[r.id];
			return a ? a.weeklyContribution < 0 : false;
		}).length
	);
	const idle = $derived(store.state.availableFleet.length);
</script>

<div class="monitor">
	<span class="title">Network monitor</span>
	<div class="row"><span class="k">Routes</span><span class="v tnum">{routes.length}</span></div>
	<div class="row">
		<span class="k">Weekly contrib.</span>
		<span class="v tnum" style="color: {totalWeekly >= 0 ? colors.success : colors.error};"
			>{money(totalWeekly)}</span
		>
	</div>
	<div class="row">
		<span class="k">Losing routes</span><span
			class="v tnum"
			style="color: {weak > 0 ? colors.error : colors.success};">{weak}</span
		>
	</div>
	<div class="row">
		<span class="k">Idle aircraft</span><span
			class="v tnum"
			style="color: {idle > 0 ? colors.warning : colors.neutral};">{idle}</span
		>
	</div>
</div>

<style>
	.monitor {
		width: 200px;
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		padding: var(--space-md);
		background: color-mix(in srgb, var(--color-surface) 88%, transparent);
		backdrop-filter: blur(8px);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
	}
	.title {
		font-size: 10px;
		font-weight: 600;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		color: var(--color-text-muted);
		margin-bottom: var(--space-xs);
	}
	.row {
		display: flex;
		justify-content: space-between;
		gap: var(--space-sm);
	}
	.k {
		font-size: 11px;
		color: var(--color-text-secondary);
	}
	.v {
		font-size: 12px;
		font-weight: 600;
	}
</style>
