<script lang="ts">
	import { untrack } from 'svelte';
	import AppDialogShell from '$lib/core/components/AppDialogShell.svelte';
	import TactileButton from '$lib/core/components/TactileButton.svelte';
	import type { RoutesStore } from '../state/routes-store.svelte';
	import type { UserRoute } from '../domain/route-models';
	import type { RoutePlanAssessment } from '../domain/route-assessment';

	type Props = {
		store: RoutesStore;
		route: UserRoute;
		baseFare: { base: number; perKm: number };
		onclose: () => void;
	};

	let { store, route, baseFare, onclose }: Props = $props();

	let ticketPrice = $state(untrack(() => route.ticketPrice));
	let flightsPerWeek = $state(untrack(() => route.flightsPerWeek));
	let assessment = $state<RoutePlanAssessment | null>(null);
	let assessing = $state(false);
	let saving = $state(false);

	const idealFare = $derived(
		Math.max(1, Math.round(baseFare.base + route.distanceKm * baseFare.perKm))
	);
	const fareRatio = $derived((ticketPrice / idealFare).toFixed(2));

	$effect(() => {
		const price = ticketPrice;
		const flights = flightsPerWeek;
		const timer = setTimeout(async () => {
			assessing = true;
			assessment = await store.assess({
				originIata: route.originIata,
				destinationIata: route.destinationIata,
				ticketPrice: price,
				flightsPerWeek: flights,
				aircraftId: route.assignedAircraftId ?? undefined
			});
			assessing = false;
		}, 300);
		return () => clearTimeout(timer);
	});

	async function handleSave() {
		saving = true;
		const ok = await store.update(route.id, ticketPrice, flightsPerWeek);
		saving = false;
		if (ok) onclose();
	}
</script>

<AppDialogShell
	title="Edit Route: {route.originIata} → {route.destinationIata}"
	subtitle="{Math.round(route.distanceKm)} km · Recommended Fare: ${idealFare}"
	{onclose}
>
	{#snippet children()}
		<div class="edit-form">
			<div class="field">
				<label for="price">Ticket Price ($ USD)</label>
				<div class="input-row">
					<input id="price" type="number" min="10" max="10000" bind:value={ticketPrice} />
					<span class="ratio" class:warn={+fareRatio > 1.3} class:ok={+fareRatio <= 1.1}>
						{fareRatio}x Market
					</span>
				</div>
				<input
					class="slider"
					type="range"
					min="10"
					max={Math.max(idealFare * 2.5, 500)}
					bind:value={ticketPrice}
				/>
			</div>

			<div class="field">
				<label for="flights">Flights Per Week</label>
				<div class="input-row">
					<input id="flights" type="number" min="1" max="28" bind:value={flightsPerWeek} />
					<span class="ratio">{flightsPerWeek * 2} Legs/Wk</span>
				</div>
				<input class="slider" type="range" min="1" max="28" bind:value={flightsPerWeek} />
			</div>

			{#if assessment}
				<div class="assessment-box">
					<span class="box-title"
						>PROJECTED ROUTE ECONOMICS ({assessment.viability.band.toUpperCase()})</span
					>
					<div class="kpi-grid">
						<div>
							<span class="k">Exp. Pax / Flight</span>
							<span class="v tnum"
								>{Math.round(assessment.expectedPassengersPerFlight)} / {assessment.seatCapacity}</span
							>
						</div>
						<div>
							<span class="k">Expected Load Factor</span>
							<span class="v ok tnum">{Math.round(assessment.loadFactorPercent)}%</span>
						</div>
						<div>
							<span class="k">Est. Weekly Revenue</span>
							<span class="v ok tnum"
								>${Math.round(assessment.weeklyRevenue).toLocaleString('en-US')}</span
							>
						</div>
						<div>
							<span class="k">Net Contribution</span>
							<span
								class="v tnum"
								class:ok={assessment.weeklyContribution >= 0}
								class:warn={assessment.weeklyContribution < 0}
							>
								${Math.round(assessment.weeklyContribution).toLocaleString('en-US')}
							</span>
						</div>
					</div>
				</div>
			{:else if assessing}
				<div class="evaluating">Evaluating route economics with telemetry…</div>
			{/if}
		</div>
	{/snippet}

	{#snippet actions()}
		<TactileButton text="Cancel" type="secondary" onclick={onclose} />
		<TactileButton text="Save Changes" type="primary" loading={saving} onclick={handleSave} />
	{/snippet}
</AppDialogShell>

<style>
	.edit-form {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
	}
	.field {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
	}
	label {
		font-size: 11px;
		font-weight: 600;
		letter-spacing: 0.06em;
		text-transform: uppercase;
		color: var(--color-text-secondary);
	}
	.input-row {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
	}
	input[type='number'] {
		flex: 1;
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-sm);
		padding: var(--space-xs) var(--space-sm);
		color: var(--color-text-primary);
		font-family: var(--font-mono);
		font-size: 14px;
	}
	.slider {
		width: 100%;
		accent-color: var(--color-accent);
		cursor: pointer;
	}
	.ratio {
		font-size: 11px;
		font-family: var(--font-mono);
		padding: 3px 6px;
		border-radius: var(--radius-sm);
		background: var(--color-surface-2);
		color: var(--color-text-secondary);
		white-space: nowrap;
	}
	.ratio.ok {
		color: var(--color-success);
	}
	.ratio.warn {
		color: var(--color-warning);
	}
	.assessment-box {
		padding: var(--space-sm);
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-sm);
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
	}
	.box-title {
		font-size: 10px;
		font-weight: 700;
		letter-spacing: 0.08em;
		color: var(--color-accent);
	}
	.kpi-grid {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: var(--space-sm);
	}
	.k {
		display: block;
		font-size: 10px;
		color: var(--color-text-muted);
		text-transform: uppercase;
	}
	.v {
		font-size: 13px;
		font-weight: 600;
	}
	.v.ok {
		color: var(--color-success);
	}
	.v.warn {
		color: var(--color-warning);
	}
	.evaluating {
		font-size: 12px;
		color: var(--color-text-muted);
		font-style: italic;
	}
</style>
