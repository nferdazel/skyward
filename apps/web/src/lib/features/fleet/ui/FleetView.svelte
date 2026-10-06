<script lang="ts">
	import AppBadge from '$lib/core/components/AppBadge.svelte';
	import CraftCard from '$lib/core/components/CraftCard.svelte';
	import SegmentedPillControl from '$lib/core/components/SegmentedPillControl.svelte';
	import FlightConditionCell from './FlightConditionCell.svelte';
	import FleetDrawerContent from './FleetDrawerContent.svelte';
	import AcquireTab from './AcquireTab.svelte';
	import type { FleetStore } from '../state/fleet-store.svelte';
	import type { UserFleetAircraft, AircraftModel } from '../domain/fleet-models';
	import { isMaintenanceGrounded } from '../domain/fleet-models';

	/**
	 * Fleet view. Ported from Flutter `FleetView`.
	 * Two segmented tabs (Active Fleet / Acquire Aircraft); the active tab shows
	 * a summary strip and a master-detail (table + inspector drawer).
	 */
	type Props = {
		store: FleetStore;
		autoGroundingThreshold?: number;
		creditTier?: string | null;
		onFinance?: (model: AircraftModel, downPaymentPct: number, termMonths: number) => Promise<void>;
	};
	let { store, autoGroundingThreshold = 40, creditTier = null, onFinance }: Props = $props();

	let tab = $state<'fleet' | 'acquire'>('fleet');
	let selectedId = $state<string | null>(null);
	let busy = $state(false);

	const fmt = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${fmt.format(Math.round(n))}`;

	const fleet = $derived(store.state.aircraft);
	const selected = $derived(fleet.find((a) => a.id === selectedId) ?? fleet[0] ?? null);
	const ready = $derived(
		fleet.filter((a) => !isMaintenanceGrounded(a, autoGroundingThreshold)).length
	);
	const grounded = $derived(
		fleet.filter((a) => isMaintenanceGrounded(a, autoGroundingThreshold)).length
	);
	const leaseBurn = $derived(
		fleet
			.filter((a) => a.acquisitionType === 'lease')
			.reduce((s, a) => s + a.model.leasePricePerMonth, 0)
	);
	const repairAll = $derived(fleet.reduce((s, a) => s + a.repairCost, 0));

	async function repair(a: UserFleetAircraft) {
		busy = true;
		await store.repair(a.id);
		busy = false;
	}

	async function saveSeats(a: UserFleetAircraft, eco: number, bus: number, first: number) {
		busy = true;
		await store.configureSeats(a.id, {
			economySeats: eco,
			businessSeats: bus,
			firstClassSeats: first
		});
		busy = false;
	}

	async function sell(a: UserFleetAircraft) {
		busy = true;
		await store.sell(a.id);
		busy = false;
	}

	async function terminateLease(a: UserFleetAircraft) {
		busy = true;
		await store.terminateLease(a.id);
		busy = false;
	}
</script>

<section>
	<SegmentedPillControl
		items={[
			{ value: 'fleet', label: 'Active Fleet' },
			{ value: 'acquire', label: 'Acquire Aircraft' }
		]}
		selected={tab}
		onselect={(v) => (tab = v === 'acquire' ? 'acquire' : 'fleet')}
	/>

	{#if store.state.error}
		<p class="err" role="alert">{store.state.error}</p>
	{/if}

	{#if tab === 'fleet'}
		{#if store.state.loading && fleet.length === 0}
			<p class="muted">Loading fleet registry…</p>
		{:else if fleet.length === 0}
			<CraftCard>
				<p class="muted">No aircraft yet. Acquire one from the Fleet tab.</p>
			</CraftCard>
		{:else}
			<CraftCard>
				<div class="summary">
					<div class="kpi"><span class="k">Ready</span><span class="v ok">{ready}</span></div>
					<span class="vline"></span>
					<div class="kpi">
						<span class="k">Grounded</span><span class="v bad">{grounded}</span>
					</div>
					<span class="vline"></span>
					<div class="kpi">
						<span class="k">Lease Burn</span><span class="v warn">{money(leaseBurn)}</span>
					</div>
					<span class="vline"></span>
					<div class="kpi">
						<span class="k">Repair All</span><span class="v bad">{money(repairAll)}</span>
					</div>
				</div>
			</CraftCard>

			<div class="md">
				<div class="master">
					<table>
						<thead>
							<tr>
								<th>Aircraft</th>
								<th>Acquisition</th>
								<th>Condition</th>
								<th>Status</th>
								<th>Cabin</th>
							</tr>
						</thead>
						<tbody>
							{#each fleet as a (a.id)}
								<tr class:selected={a.id === selected?.id} onclick={() => (selectedId = a.id)}>
									<td>
										<div class="ac">
											<AppBadge label={a.tailNumber || '—'} tone="primary" />
											<span class="model">{a.model.modelName || 'Unknown'}</span>
										</div>
										<span class="mfr">{a.model.manufacturer.toUpperCase()}</span>
									</td>
									<td>
										<AppBadge
											label={a.acquisitionType}
											tone={a.acquisitionType === 'lease' ? 'warning' : 'secondary'}
										/>
									</td>
									<td><FlightConditionCell condition={a.condition} /></td>
									<td>
										<AppBadge
											label={isMaintenanceGrounded(a, autoGroundingThreshold)
												? 'grounded'
												: a.status}
											tone={isMaintenanceGrounded(a, autoGroundingThreshold) ? 'error' : 'success'}
										/>
									</td>
									<td class="tnum">E {a.economySeats} B {a.businessSeats} F {a.firstClassSeats}</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>

				<div class="detail">
					{#if selected}
						<FleetDrawerContent
							aircraft={selected}
							{autoGroundingThreshold}
							{busy}
							onRepair={() => repair(selected)}
							onSaveSeats={(e, b, f) => saveSeats(selected, e, b, f)}
							onSell={() => sell(selected)}
							onTerminateLease={() => terminateLease(selected)}
						/>
					{/if}
				</div>
			</div>
		{/if}
	{:else}
		<AcquireTab {store} {creditTier} {onFinance} />
	{/if}
</section>

<style>
	section {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
	}
	.err {
		color: var(--color-error);
		font-size: 13px;
	}
	.muted {
		color: var(--color-text-muted);
		font-size: 13px;
	}
	.summary {
		display: flex;
		align-items: center;
	}
	.kpi {
		flex: 1;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: var(--space-xs);
	}
	.k {
		font-size: 10px;
		color: var(--color-text-muted);
		letter-spacing: 0.08em;
		text-transform: uppercase;
	}
	.v {
		font-size: 14px;
		font-weight: 600;
		font-variant-numeric: tabular-nums;
	}
	.ok {
		color: var(--color-success);
	}
	.bad {
		color: var(--color-error);
	}
	.warn {
		color: var(--color-warning);
	}
	.vline {
		width: 1px;
		height: 28px;
		background: var(--color-border);
	}
	.md {
		display: flex;
		min-height: 0;
		gap: 0;
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		overflow: hidden;
	}
	.master {
		flex: 68;
		min-width: 0;
		overflow: auto;
	}
	.detail {
		flex: 32;
		min-width: 0;
		overflow: auto;
		background: var(--color-surface);
		border-left: 1px solid var(--color-border);
		padding: var(--space-md);
	}
	table {
		width: 100%;
		border-collapse: collapse;
		font-size: 13px;
	}
	th {
		text-align: left;
		padding: var(--space-sm) var(--space-md);
		background: var(--color-surface-2);
		color: var(--color-text-secondary);
		font-size: 10px;
		font-weight: 600;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		border-bottom: 1px solid var(--color-border);
		white-space: nowrap;
	}
	td {
		padding: var(--space-sm) var(--space-md);
		border-bottom: 1px solid var(--color-border);
	}
	tbody tr {
		cursor: pointer;
	}
	tbody tr:hover td {
		background: rgb(36 46 61 / 0.4);
	}
	tbody tr.selected td {
		background: var(--color-surface-active);
	}
	.ac {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
	}
	.model {
		font-weight: 700;
		color: var(--color-text-primary);
	}
	.mfr {
		font-size: 10px;
		letter-spacing: 0.1em;
		color: var(--color-text-secondary);
	}
	@media (max-width: 1050px) {
		.detail {
			display: none;
		}
	}
</style>
