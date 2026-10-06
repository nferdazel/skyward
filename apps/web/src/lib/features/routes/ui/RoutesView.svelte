<script lang="ts">
	import RouteMapOverlay from './RouteMapOverlay.svelte';
	import RouteListPanel from './RouteListPanel.svelte';
	import SystemMonitor from './SystemMonitor.svelte';
	import BlueprintPlanner from './BlueprintPlanner.svelte';
	import type { RoutesStore } from '../state/routes-store.svelte';
	import type { Airport } from '../domain/airport';

	/**
	 * Routes view. Ported from Flutter `RoutesView`: a full-screen map base layer
	 * with overlay panels — left route list, top-right system monitor, bottom
	 * blueprint planner.
	 */
	type Props = {
		store: RoutesStore;
		autoGroundingThreshold?: number;
		baseFare?: { base: number; perKm: number };
	};
	let {
		store,
		autoGroundingThreshold = 40,
		baseFare = { base: 50, perKm: 0.12 }
	}: Props = $props();

	let selectedRouteId = $state<string | null>(null);
	let plannerOrigin = $state<Airport | null>(null);
	let plannerDestination = $state<Airport | null>(null);

	const routes = $derived(store.state.routes);

	function toggleSelect(id: string) {
		selectedRouteId = selectedRouteId === id ? null : id;
	}

	function mapTap(a: Airport) {
		// Clicking an airport fills the planner: origin if empty, else destination.
		if (!plannerOrigin || (plannerOrigin && plannerDestination)) {
			plannerOrigin = a;
			plannerDestination = null;
		} else if (a.iata !== plannerOrigin.iata) {
			plannerDestination = a;
		}
	}
</script>

<section class="routes">
	<div class="map-layer">
		<RouteMapOverlay
			airports={store.state.airports}
			{routes}
			preview={plannerOrigin && plannerDestination
				? { origin: plannerOrigin, destination: plannerDestination }
				: null}
			onmaptap={mapTap}
		/>
	</div>

	{#if store.state.error}
		<p class="err" role="alert">{store.state.error}</p>
	{/if}

	{#if routes.length > 0}
		<div class="left-panel">
			<RouteListPanel
				{store}
				{routes}
				{selectedRouteId}
				{autoGroundingThreshold}
				{baseFare}
				ontoggle={toggleSelect}
			/>
		</div>
	{:else if !store.state.loading}
		<div class="empty-hint" role="status">
			<p class="empty-title">No routes yet</p>
			<p class="empty-body">
				Use the Blueprint planner below: pick an origin and destination, review the server
				assessment, then open the route.
			</p>
		</div>
	{:else}
		<div class="loading-hint" role="status" aria-live="polite">Loading routes…</div>
	{/if}

	<div class="monitor">
		<SystemMonitor {store} {routes} />
	</div>

	<div class="planner" style="left: {routes.length > 0 ? '260px' : '0'};">
		<BlueprintPlanner
			{store}
			airports={store.state.airports}
			{routes}
			bind:origin={plannerOrigin}
			bind:destination={plannerDestination}
			{baseFare}
		/>
	</div>
</section>

<style>
	.routes {
		position: relative;
		height: 100%;
		min-height: 480px;
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		overflow: hidden;
	}
	.map-layer {
		position: absolute;
		inset: 0;
		z-index: 1;
		/* Isolate Leaflet's internal controls (z-index 1000+) so overlay panels
		   (z-index 20) always sit above the map. */
		isolation: isolate;
	}
	.left-panel {
		position: absolute;
		top: 0;
		bottom: 0;
		left: 0;
		width: 260px;
		z-index: 20;
	}
	.monitor {
		position: absolute;
		top: var(--space-lg);
		right: var(--space-lg);
		z-index: 20;
	}
	.planner {
		position: absolute;
		bottom: 0;
		right: 0;
		z-index: 20;
	}
	.err {
		position: absolute;
		top: var(--space-lg);
		left: var(--space-lg);
		z-index: 30;
		color: var(--color-error);
		font-size: 13px;
	}
	.empty-hint {
		position: absolute;
		top: 50%;
		left: 50%;
		transform: translate(-50%, -50%);
		z-index: 15;
		max-width: 360px;
		padding: var(--space-lg);
		text-align: center;
		background: color-mix(in srgb, var(--color-surface) 88%, transparent);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		backdrop-filter: blur(6px);
	}
	.empty-title {
		margin: 0 0 var(--space-xs);
		font-weight: 600;
		color: var(--color-text-primary);
	}
	.empty-body {
		margin: 0;
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.loading-hint {
		position: absolute;
		top: var(--space-lg);
		left: var(--space-lg);
		z-index: 15;
		padding: var(--space-sm) var(--space-md);
		font-size: 12px;
		color: var(--color-text-secondary);
		background: color-mix(in srgb, var(--color-surface) 88%, transparent);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
	}
</style>
