<script lang="ts">
	import CraftCard from '$lib/core/components/CraftCard.svelte';
	import TactileButton from '$lib/core/components/TactileButton.svelte';
	import SearchableAirportDropdown from '$lib/core/components/SearchableAirportDropdown.svelte';
	import type { RoutesStore } from '../state/routes-store.svelte';
	import type { Airport } from '../domain/airport';
	import { calculateDistance } from '../domain/airport';
	import type { UserRoute } from '../domain/route-models';
	import type { RoutePlanAssessment } from '../domain/route-assessment';
	import { colors } from '$lib/core/theme/tokens';

	/**
	 * Bottom overlay planner. Ported from the Flutter `_buildBlueprintPlannerPanel`:
	 * pick origin/destination, set fare and frequency, see the server assessment
	 * (weekly contribution, viability) before opening the route.
	 */
	type Props = {
		store: RoutesStore;
		airports: Airport[];
		routes: UserRoute[];
		origin: Airport | null;
		destination: Airport | null;
		baseFare: { base: number; perKm: number };
	};

	let {
		store,
		airports,
		origin = $bindable(null),
		destination = $bindable(null),
		baseFare
	}: Props = $props();

	let fare = $state(0);
	let freq = $state(7);
	let assessment = $state<RoutePlanAssessment | null>(null);
	let busy = $state(false);

	const distanceKm = $derived(origin && destination ? calculateDistance(origin, destination) : 0);
	const idealFare = $derived(distanceKm > 0 ? baseFare.base + distanceKm * baseFare.perKm : 0);

	// Suggest an initial fare from the server's formula when the leg is chosen.
	$effect(() => {
		if (origin && destination && distanceKm > 0) {
			fare = Math.round(idealFare);
			void assess();
		}
	});

	async function assess() {
		if (!origin || !destination) return;
		assessment = await store.assess({
			originIata: origin.iata,
			destinationIata: destination.iata,
			ticketPrice: fare,
			flightsPerWeek: freq
		});
	}

	async function open() {
		if (!origin || !destination) return;
		busy = true;
		await store.create({
			originIata: origin.iata,
			destinationIata: destination.iata,
			distanceKm,
			ticketPrice: fare,
			flightsPerWeek: freq
		});
		busy = false;
		origin = null;
		destination = null;
		assessment = null;
	}

	function reset() {
		origin = null;
		destination = null;
		assessment = null;
	}
</script>

<CraftCard>
	<div class="planner">
		<span class="label">Blueprint planner</span>

		<div class="field">
			<SearchableAirportDropdown
				{airports}
				value={origin}
				label="Origin"
				onselect={(a) => (origin = a)}
			/>
		</div>
		<div class="field">
			<SearchableAirportDropdown
				{airports}
				value={destination}
				label="Destination"
				onselect={(a) => (destination = a)}
			/>
		</div>
		<label class="field">
			<span>Fare</span>
			<input type="number" bind:value={fare} onblur={assess} min="0" />
		</label>
		<label class="field">
			<span>Flights / week</span>
			<input type="number" bind:value={freq} onblur={assess} min="1" max="168" />
		</label>

		<div class="readout">
			<span class="muted"
				>{Math.round(distanceKm)} km · ideal {idealFare > 0
					? `$${Math.round(idealFare)}`
					: '—'}</span
			>
			{#if assessment}
				<span
					class="contrib"
					style="color: {assessment.weeklyContribution >= 0 ? colors.success : colors.error};"
				>
					{assessment.weeklyContribution >= 0 ? '+' : ''}${Math.round(
						assessment.weeklyContribution
					)}/wk
				</span>
				<span class="band" data-band={assessment.viability.band}>{assessment.viability.band}</span>
			{/if}
		</div>

		<div class="actions">
			<TactileButton text="Reset" type="ghost" onclick={reset} />
			<TactileButton
				text="Open route"
				type="primary"
				loading={busy}
				onclick={origin && destination && distanceKm > 0 ? open : undefined}
			/>
		</div>
	</div>
</CraftCard>

<style>
	.planner {
		display: flex;
		align-items: flex-end;
		gap: var(--space-md);
		flex-wrap: wrap;
	}
	.label {
		font-size: 10px;
		font-weight: 600;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		color: var(--color-text-muted);
		align-self: center;
		margin-right: var(--space-sm);
	}
	.field {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		font-size: 10px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--color-text-secondary);
	}
	input {
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		color: var(--color-text-primary);
		padding: var(--space-sm);
		font-size: 13px;
		min-width: 120px;
	}
	input[type='number'] {
		width: 90px;
	}
	.readout {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		align-items: flex-end;
		margin-left: auto;
	}
	.muted {
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.contrib {
		font-size: 16px;
		font-weight: 700;
		font-variant-numeric: tabular-nums;
	}
	.band {
		font-size: 10px;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: var(--color-text-muted);
	}
	.actions {
		display: flex;
		gap: var(--space-sm);
	}
</style>
