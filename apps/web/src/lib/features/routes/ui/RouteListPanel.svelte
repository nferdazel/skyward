<script lang="ts">
	import type { RoutesStore } from '../state/routes-store.svelte';
	import type { UserRoute } from '../domain/route-models';
	import { isMaintenanceGrounded } from '$lib/features/fleet/domain/fleet-models';
	import { colors } from '$lib/core/theme/tokens';

	/**
	 * Left overlay panel: scrollable list of route cards. Ported from the Flutter
	 * `_buildRouteListPanel` + `_buildRouteCard` (IATA boxes, status badge,
	 * distance·frequency, fare coloured by pricing ratio).
	 */
	type Props = {
		store: RoutesStore;
		routes: UserRoute[];
		selectedRouteId: string | null;
		autoGroundingThreshold: number;
		baseFare: { base: number; perKm: number };
		ontoggle: (id: string) => void;
	};

	let { store, routes, selectedRouteId, autoGroundingThreshold, baseFare, ontoggle }: Props =
		$props();

	const money = (n: number) => `$${Math.round(n).toLocaleString('en-US')}`;

	type Status = { color: string; label: string };
	function statusOf(route: UserRoute): Status {
		const aircraft = route.assignedAircraft;
		if (aircraft === null) return { color: colors.error, label: 'GROUNDED' };
		if (isMaintenanceGrounded(aircraft, autoGroundingThreshold))
			return { color: colors.error, label: 'GROUNDED' };
		const wear = store.state.assessments[route.id]?.wear.netPerWeek ?? 0;
		if (wear > 0) return { color: colors.warning, label: 'PRESSURED' };
		return { color: colors.success, label: 'ACTIVE' };
	}

	function fareColor(route: UserRoute): string {
		const ideal = baseFare.base + route.distanceKm * baseFare.perKm;
		const ratio = ideal > 0 ? route.ticketPrice / ideal : 1;
		if (ratio <= 1) return colors.success;
		if (ratio <= 1.5) return colors.warning;
		return colors.error;
	}

	async function close(route: UserRoute) {
		await store.remove(route.id);
	}

	function toggleAssign(route: UserRoute) {
		// Unassign if assigned; otherwise assign the first idle-ready aircraft.
		if (route.assignedAircraftId) {
			void store.assign(route.id, null);
			return;
		}
		const idle = store.state.availableFleet[0];
		if (idle) void store.assign(route.id, idle.id);
	}
</script>

<div class="panel">
	<div class="head">
		<span class="title">Route network</span>
		<span class="count">{routes.length}</span>
	</div>
	<ul>
		{#each routes as route (route.id)}
			{@const sel = route.id === selectedRouteId}
			{@const st = statusOf(route)}
			<li class="card" class:sel>
				<button class="card-main" onclick={() => ontoggle(route.id)}>
					<div class="top">
						<span class="legs">
							<span class="iata">{route.originIata}</span>
							<span class="arrow">→</span>
							<span class="iata">{route.destinationIata}</span>
						</span>
						<span class="status" style="color: {st.color}; background: {st.color}1f;"
							>{st.label}</span
						>
					</div>
					<div class="bottom">
						<span class="meta">{Math.round(route.distanceKm)} KM · {route.flightsPerWeek}X/WK</span>
						<span class="fare" style="color: {fareColor(route)};">{money(route.ticketPrice)}</span>
					</div>
				</button>
				{#if sel}
					<div class="actions">
						<button onclick={() => toggleAssign(route)}>Assign</button>
						<button class="danger" onclick={() => close(route)}>Close</button>
					</div>
				{/if}
			</li>
		{/each}
	</ul>
</div>

<style>
	.panel {
		height: 100%;
		display: flex;
		flex-direction: column;
		background: color-mix(in srgb, var(--color-surface) 82%, transparent);
		backdrop-filter: blur(8px);
		border-right: 1px solid var(--color-border);
	}
	.head {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
		padding: var(--space-md);
		border-bottom: 1px solid var(--color-border);
	}
	.title {
		font-size: 11px;
		font-weight: 600;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		color: var(--color-text-secondary);
	}
	.count {
		margin-left: auto;
		font-size: 12px;
		color: var(--color-accent);
	}
	ul {
		list-style: none;
		margin: 0;
		padding: var(--space-sm);
		overflow-y: auto;
		flex: 1;
	}
	.card {
		margin-bottom: var(--space-xs);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		background: color-mix(in srgb, var(--color-surface) 60%, transparent);
	}
	.card.sel {
		background: var(--color-accent-subtle);
		border-color: color-mix(in srgb, var(--color-accent) 40%, transparent);
	}
	.card-main {
		width: 100%;
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		padding: var(--space-sm);
		background: none;
		border: none;
		cursor: pointer;
		color: inherit;
		font: inherit;
		text-align: left;
	}
	.top,
	.bottom {
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: var(--space-sm);
	}
	.legs {
		display: inline-flex;
		align-items: center;
		gap: var(--space-xs);
	}
	.iata {
		padding: 2px 4px;
		border-radius: var(--radius-tight);
		background: color-mix(in srgb, var(--color-accent) 12%, transparent);
		color: var(--color-accent);
		font-size: 11px;
		font-weight: 600;
	}
	.arrow {
		color: var(--color-accent);
		font-size: 10px;
	}
	.status {
		font-size: 10px;
		font-weight: 600;
		padding: 1px 6px;
		border-radius: var(--radius-default);
	}
	.meta {
		font-size: 11px;
		color: var(--color-text-muted);
	}
	.fare {
		font-size: 13px;
		font-weight: 700;
		font-variant-numeric: tabular-nums;
	}
	.actions {
		display: flex;
		gap: var(--space-xs);
		padding: 0 var(--space-sm) var(--space-sm);
	}
	.actions button {
		flex: 1;
		padding: var(--space-xs);
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-tight);
		color: var(--color-text-secondary);
		font-size: 11px;
		cursor: pointer;
	}
	.actions button:hover {
		color: var(--color-accent);
	}
	.actions .danger:hover {
		color: var(--color-error);
	}
</style>
