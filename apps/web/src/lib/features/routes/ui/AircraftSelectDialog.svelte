<script lang="ts">
	import AppDialogShell from '$lib/core/components/AppDialogShell.svelte';
	import AppBadge from '$lib/core/components/AppBadge.svelte';
	import TactileButton from '$lib/core/components/TactileButton.svelte';
	import FlightConditionCell from '$lib/features/fleet/ui/FlightConditionCell.svelte';
	import type { RoutesStore } from '../state/routes-store.svelte';
	import type { UserRoute } from '../domain/route-models';
	import type { UserFleetAircraft } from '$lib/features/fleet/domain/fleet-models';
	import { isMaintenanceGrounded } from '$lib/features/fleet/domain/fleet-models';

	type Props = {
		store: RoutesStore;
		route: UserRoute;
		autoGroundingThreshold: number;
		onclose: () => void;
	};

	let { store, route, autoGroundingThreshold, onclose }: Props = $props();

	let assigningId = $state<string | null>(null);
	let unassigning = $state(false);

	const availableFleet = $derived(store.state.availableFleet);
	const assigned = $derived(route.assignedAircraft);

	async function assign(aircraft: UserFleetAircraft) {
		assigningId = aircraft.id;
		const ok = await store.assign(route.id, aircraft.id);
		assigningId = null;
		if (ok) onclose();
	}

	async function unassign() {
		unassigning = true;
		const ok = await store.assign(route.id, null);
		unassigning = false;
		if (ok) onclose();
	}
</script>

<AppDialogShell
	title="Fleet Assignment: {route.originIata} → {route.destinationIata}"
	subtitle="{Math.round(route.distanceKm)} km · {route.flightsPerWeek} flights/week"
	{onclose}
>
	{#snippet children()}
		<div class="assign-dialog">
			{#if assigned}
				<div class="current-card">
					<div class="header">
						<span class="micro-label">Currently Assigned</span>
						<TactileButton
							text={unassigning ? 'Unassigning…' : 'Unassign'}
							type="destructive"
							height="24px"
							disabled={unassigning}
							onclick={unassign}
						/>
					</div>
					<div class="info">
						<span class="tail">{assigned.tailNumber}</span>
						<span class="model"
							>{assigned.model.modelName} ({assigned.model.manufacturer.toUpperCase()})</span
						>
						<div class="meta">
							<span>Range: {assigned.model.rangeKm} km</span>
							<span>·</span>
							<span
								>Seats: {assigned.economySeats +
									assigned.businessSeats +
									assigned.firstClassSeats}</span
							>
						</div>
					</div>
				</div>
			{/if}

			<div class="section-title">
				<span>Available Idle Fleet ({availableFleet.length})</span>
			</div>

			{#if availableFleet.length === 0}
				<div class="empty">
					<p>No idle aircraft available in your fleet.</p>
					<p class="sub">Acquire or unassign an aircraft to deploy to this route.</p>
				</div>
			{:else}
				<div class="fleet-list">
					{#each availableFleet as a (a.id)}
						{@const rangeOk = a.model.rangeKm >= route.distanceKm}
						{@const grounded = isMaintenanceGrounded(a, autoGroundingThreshold)}
						{@const canAssign = rangeOk && !grounded}
						<div class="aircraft-item" class:disabled={!canAssign}>
							<div class="left">
								<div class="primary-row">
									<AppBadge label={a.tailNumber || '—'} tone="primary" />
									<span class="name">{a.model.modelName}</span>
									<span class="mfr">{a.model.manufacturer.toUpperCase()}</span>
								</div>
								<div class="stats-row">
									<span class="stat">
										Range: <strong>{a.model.rangeKm} km</strong>
										{#if !rangeOk}
											<span class="badge-err">DEFICIT</span>
										{/if}
									</span>
									<span class="stat">Cap: <strong>{a.model.capacity} pax</strong></span>
									<span class="stat">Cond: <FlightConditionCell condition={a.condition} /></span>
								</div>
							</div>

							<div class="right">
								{#if !rangeOk}
									<span class="status-msg bad">Too far for aircraft</span>
								{:else if grounded}
									<span class="status-msg bad">Grounded</span>
								{:else}
									<TactileButton
										text={assigningId === a.id ? 'Assigning…' : 'Select'}
										type="primary"
										height="30px"
										disabled={assigningId !== null}
										onclick={() => assign(a)}
									/>
								{/if}
							</div>
						</div>
					{/each}
				</div>
			{/if}
		</div>
	{/snippet}

	{#snippet actions()}
		<TactileButton text="Close" type="secondary" onclick={onclose} />
	{/snippet}
</AppDialogShell>

<style>
	.assign-dialog {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
	}
	.current-card {
		padding: var(--space-sm);
		background: var(--color-surface-2);
		border: 1px solid var(--color-accent);
		border-radius: var(--radius-sm);
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
	}
	.header {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}
	.info {
		display: flex;
		align-items: baseline;
		gap: var(--space-sm);
		flex-wrap: wrap;
	}
	.tail {
		font-family: var(--font-mono);
		font-weight: 700;
		color: var(--color-accent);
	}
	.model {
		font-weight: 600;
		color: var(--color-text-primary);
	}
	.meta {
		display: flex;
		gap: var(--space-xs);
		font-size: 11px;
		color: var(--color-text-secondary);
	}
	.section-title {
		font-size: 11px;
		font-weight: 600;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--color-text-secondary);
	}
	.fleet-list {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		max-height: 380px;
		overflow-y: auto;
	}
	.aircraft-item {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: var(--space-sm);
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-sm);
		gap: var(--space-sm);
	}
	.aircraft-item.disabled {
		opacity: 0.6;
	}
	.left {
		display: flex;
		flex-direction: column;
		gap: 4px;
	}
	.primary-row {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
	}
	.name {
		font-weight: 700;
		color: var(--color-text-primary);
	}
	.mfr {
		font-size: 10px;
		letter-spacing: 0.08em;
		color: var(--color-text-secondary);
	}
	.stats-row {
		display: flex;
		align-items: center;
		gap: var(--space-md);
		font-size: 11px;
		color: var(--color-text-secondary);
	}
	.badge-err {
		margin-left: 4px;
		font-size: 9px;
		padding: 1px 4px;
		background: rgb(224 85 85 / 0.2);
		color: var(--color-error);
		border-radius: 2px;
		font-weight: 700;
	}
	.status-msg.bad {
		font-size: 11px;
		color: var(--color-error);
		font-weight: 600;
	}
	.empty {
		padding: var(--space-lg);
		text-align: center;
		color: var(--color-text-muted);
		background: var(--color-surface-2);
		border-radius: var(--radius-sm);
		font-size: 13px;
	}
	.empty .sub {
		font-size: 11px;
		margin-top: 4px;
	}
</style>
