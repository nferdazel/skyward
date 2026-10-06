<script lang="ts">
	import { untrack } from 'svelte';
	import AppBadge from '$lib/core/components/AppBadge.svelte';
	import TactileButton from '$lib/core/components/TactileButton.svelte';
	import FlightConditionCell from './FlightConditionCell.svelte';
	import type { UserFleetAircraft } from '../domain/fleet-models';
	import {
		effectivePassengerCapacity,
		isMaintenanceGrounded,
		isOwned
	} from '../domain/fleet-models';

	/**
	 * Inspector content for the selected aircraft. Ported from Flutter
	 * `FleetDrawerContent`: identity, condition, economics (from server), cabin
	 * editor, and actions.
	 */
	type Props = {
		aircraft: UserFleetAircraft;
		autoGroundingThreshold: number;
		busy?: boolean;
		onRepair: () => void;
		onSaveSeats: (economy: number, business: number, first: number) => void;
	};

	let { aircraft, autoGroundingThreshold, busy = false, onRepair, onSaveSeats }: Props = $props();

	// Seed the cabin editor once; the effect below re-seeds on selection change.
	let eco = $state(untrack(() => aircraft.economySeats));
	let bus = $state(untrack(() => aircraft.businessSeats));
	let first = $state(untrack(() => aircraft.firstClassSeats));

	// Re-seed the cabin editor whenever the selected aircraft changes.
	$effect(() => {
		eco = aircraft.economySeats;
		bus = aircraft.businessSeats;
		first = aircraft.firstClassSeats;
	});

	const fmt = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${fmt.format(Math.round(n))}`;
	const grounded = $derived(isMaintenanceGrounded(aircraft, autoGroundingThreshold));
	const capacity = $derived(aircraft.model.capacity || effectivePassengerCapacity(aircraft));
	const slots = $derived(eco + bus * 2 + first * 3);
	const cabinsValid = $derived(slots <= capacity && eco >= 0 && bus >= 0 && first >= 0);
</script>

<div class="drawer">
	<header>
		<div class="id">
			<AppBadge label={aircraft.tailNumber || '—'} tone="primary" />
			<span class="model">{aircraft.model.modelName || 'Unknown'}</span>
		</div>
		<span class="mfr">{aircraft.model.manufacturer.toUpperCase()}</span>
		<div class="badges">
			<AppBadge label={aircraft.acquisitionType} tone={isOwned(aircraft) ? 'primary' : 'warning'} />
			<AppBadge
				label={grounded ? 'grounded' : aircraft.status}
				tone={grounded ? 'error' : 'success'}
			/>
		</div>
	</header>

	<dl>
		<div>
			<dt>Range</dt>
			<dd class="tnum">{aircraft.model.rangeKm} km</dd>
		</div>
		<div>
			<dt>Capacity</dt>
			<dd class="tnum">{capacity}</dd>
		</div>
		{#if isOwned(aircraft)}
			<div>
				<dt>Sale value</dt>
				<dd class="tnum">{money(aircraft.saleValue)}</dd>
			</div>
		{:else}
			<div>
				<dt>Lease / month</dt>
				<dd class="tnum">{money(aircraft.model.leasePricePerMonth)}</dd>
			</div>
			<div>
				<dt>Exit fee</dt>
				<dd class="tnum">{money(aircraft.leaseExitFee)}</dd>
			</div>
		{/if}
		<div>
			<dt>Repair cost</dt>
			<dd class="tnum">{money(aircraft.repairCost)}</dd>
		</div>
	</dl>

	<section class="condition">
		<span class="label">Condition</span>
		<FlightConditionCell condition={aircraft.condition} />
	</section>

	<section class="cabin">
		<span class="label">Cabin configuration</span>
		<div class="cabin-grid">
			<label><span>Economy</span><input type="number" min="0" bind:value={eco} /></label>
			<label><span>Business</span><input type="number" min="0" bind:value={bus} /></label>
			<label><span>First</span><input type="number" min="0" bind:value={first} /></label>
		</div>
		<p class="slots" class:bad={!cabinsValid}>
			Slots used {slots} / {capacity}
			{#if !cabinsValid}
				— exceeds capacity{/if}
		</p>
	</section>

	<div class="actions">
		<TactileButton text="Repair" type="secondary" loading={busy} onclick={onRepair} />
		<TactileButton
			text="Save cabin"
			type="primary"
			loading={busy}
			onclick={cabinsValid ? () => onSaveSeats(eco, bus, first) : undefined}
		/>
	</div>
</div>

<style>
	.drawer {
		display: flex;
		flex-direction: column;
		gap: var(--space-lg);
	}
	header {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
	}
	.id {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
	}
	.model {
		font-weight: 700;
	}
	.mfr {
		font-size: 10px;
		letter-spacing: 0.1em;
		color: var(--color-text-secondary);
	}
	.badges {
		display: flex;
		gap: var(--space-xs);
		margin-top: var(--space-xs);
	}
	dl {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin: 0;
	}
	dl > div {
		display: flex;
		justify-content: space-between;
		border-bottom: 1px solid var(--color-border-subtle);
		padding-bottom: var(--space-xs);
	}
	dt {
		color: var(--color-text-muted);
		font-size: 11px;
		text-transform: uppercase;
		letter-spacing: 0.08em;
	}
	dd {
		margin: 0;
		font-size: 14px;
	}
	.label {
		display: block;
		font-size: 11px;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: var(--color-text-muted);
		margin-bottom: var(--space-sm);
	}
	.cabin-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: var(--space-sm);
	}
	label {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		font-size: 11px;
		color: var(--color-text-secondary);
	}
	input {
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		color: var(--color-text-primary);
		padding: var(--space-sm);
		font-size: 14px;
	}
	.slots {
		margin: var(--space-sm) 0 0;
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.slots.bad {
		color: var(--color-error);
	}
	.actions {
		display: flex;
		gap: var(--space-sm);
	}
</style>
