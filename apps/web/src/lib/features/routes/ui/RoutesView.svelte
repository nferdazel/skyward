<script lang="ts">
	import AppCard from '$lib/core/components/AppCard.svelte';
	import AppButton from '$lib/core/components/AppButton.svelte';
	import AppBadge from '$lib/core/components/AppBadge.svelte';
	import AppEmptyState from '$lib/core/components/AppEmptyState.svelte';
	import AppDialogShell from '$lib/core/components/AppDialogShell.svelte';
	import RouteMapOverlay from './RouteMapOverlay.svelte';
	import type { RoutesStore } from '../state/routes-store.svelte';
	import type { UserRoute } from '../domain/route-models';
	import { calculateDistance } from '../domain/airport';

	type Props = { store: RoutesStore };
	let { store }: Props = $props();

	let view = $state<'list' | 'map'>('list');
	let dialog = $state<'create' | 'adjust' | null>(null);
	let selected = $state<UserRoute | null>(null);
	let busy = $state(false);

	// Form buat rute
	let originIata = $state('');
	let destinationIata = $state('');
	let ticketPrice = $state(0);
	let flightsPerWeek = $state(7);

	const num = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${num.format(Math.round(n))}`;

	const originAirport = $derived(store.state.airports.find((a) => a.iata === originIata) ?? null);
	const destAirport = $derived(
		store.state.airports.find((a) => a.iata === destinationIata) ?? null
	);
	const distanceKm = $derived(
		originAirport && destAirport ? calculateDistance(originAirport, destAirport) : 0
	);

	function openCreate() {
		originIata = '';
		destinationIata = '';
		ticketPrice = 0;
		flightsPerWeek = 7;
		dialog = 'create';
	}

	async function submitCreate() {
		if (!originAirport || !destAirport) return;
		busy = true;
		await store.create({
			originIata,
			destinationIata,
			distanceKm,
			ticketPrice,
			flightsPerWeek
		});
		busy = false;
		dialog = null;
	}

	function openAdjust(r: UserRoute) {
		selected = r;
		ticketPrice = r.ticketPrice;
		flightsPerWeek = r.flightsPerWeek;
		dialog = 'adjust';
	}

	async function submitAdjust() {
		if (!selected) return;
		busy = true;
		await store.update(selected.id, ticketPrice, flightsPerWeek);
		busy = false;
		dialog = null;
	}

	async function assign(route: UserRoute, aircraftId: string | null) {
		await store.assign(route.id, aircraftId);
	}

	function assessmentFor(routeId: string) {
		return store.state.assessments[routeId] ?? null;
	}
</script>

<section>
	<div class="tabs" role="tablist">
		<button
			role="tab"
			aria-selected={view === 'list'}
			class:active={view === 'list'}
			onclick={() => (view = 'list')}
		>
			List
		</button>
		<button
			role="tab"
			aria-selected={view === 'map'}
			class:active={view === 'map'}
			onclick={() => (view = 'map')}
		>
			Map
		</button>
		<div class="spacer"></div>
		<AppButton text="Open route" onclick={openCreate} />
	</div>

	{#if store.state.error}
		<p class="error" role="alert">{store.state.error}</p>
	{/if}

	{#if view === 'map'}
		<AppCard>
			<RouteMapOverlay airports={store.state.airports} routes={store.state.routes} />
		</AppCard>
	{:else}
		<AppCard>
			{#if store.state.routes.length === 0 && !store.state.loading}
				<AppEmptyState
					title="No routes yet"
					description="Open your first route between airports."
				/>
			{:else}
				<div class="table-wrap">
					<table>
						<thead>
							<tr>
								<th>Route</th>
								<th>Distance</th>
								<th>Fare</th>
								<th>Freq</th>
								<th>Weekly contrib.</th>
								<th>Actions</th>
							</tr>
						</thead>
						<tbody>
							{#each store.state.routes as r (r.id)}
								{@const assess = assessmentFor(r.id)}
								<tr>
									<td>{r.originIata}→{r.destinationIata}</td>
									<td>{Math.round(r.distanceKm)} km</td>
									<td>{money(r.ticketPrice)}</td>
									<td>{r.flightsPerWeek}/wk</td>
									<td>
										{#if assess}
											{money(assess.weeklyContribution)}
											<AppBadge
												label={assess.viability.band}
												tone={assess.weeklyContribution > 0 ? 'success' : 'error'}
											/>
										{:else}
											<span class="muted">—</span>
										{/if}
									</td>
									<td class="actions">
										<AppButton text="Adjust" variant="secondary" onclick={() => openAdjust(r)} />
										{#if r.assignedAircraftId}
											<AppButton
												text="Unassign"
												variant="secondary"
												onclick={() => assign(r, null)}
											/>
										{/if}
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{/if}
		</AppCard>
	{/if}
</section>

{#if dialog === 'create'}
	<AppDialogShell title="Open route" onclose={() => (dialog = null)}>
		{#snippet children()}
			<label
				><span>Origin (IATA)</span>
				<input bind:value={originIata} placeholder="SIN" />
			</label>
			<label
				><span>Destination (IATA)</span>
				<input bind:value={destinationIata} placeholder="KUL" />
			</label>
			<p class="sub">Distance: {Math.round(distanceKm)} km</p>
			<label><span>Ticket price</span><input type="number" bind:value={ticketPrice} /></label>
			<label><span>Flights / week</span><input type="number" bind:value={flightsPerWeek} /></label>
		{/snippet}
		{#snippet actions()}
			<AppButton text="Cancel" variant="secondary" onclick={() => (dialog = null)} />
			<AppButton
				text="Open"
				loading={busy}
				onclick={originAirport && destAirport ? submitCreate : undefined}
			/>
		{/snippet}
	</AppDialogShell>
{/if}

{#if dialog === 'adjust' && selected}
	{@const r = selected}
	<AppDialogShell
		title="Adjust route"
		subtitle="{r.originIata} → {r.destinationIata}"
		onclose={() => (dialog = null)}
	>
		{#snippet children()}
			<label><span>Ticket price</span><input type="number" bind:value={ticketPrice} /></label>
			<label><span>Flights / week</span><input type="number" bind:value={flightsPerWeek} /></label>
		{/snippet}
		{#snippet actions()}
			<AppButton text="Cancel" variant="secondary" onclick={() => (dialog = null)} />
			<AppButton text="Save" loading={busy} onclick={submitAdjust} />
		{/snippet}
	</AppDialogShell>
{/if}

<style>
	.tabs {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
		margin-bottom: var(--space-md);
	}
	.tabs button {
		background: transparent;
		border: none;
		border-bottom: 2px solid transparent;
		color: var(--color-text-secondary);
		padding: var(--space-sm) var(--space-md);
		cursor: pointer;
		font-family: var(--font-sans);
		font-weight: 600;
		font-size: 12px;
		letter-spacing: 0.06em;
		text-transform: uppercase;
	}
	.tabs button.active {
		color: var(--color-accent);
		border-bottom-color: var(--color-accent);
	}
	.spacer {
		flex: 1;
	}
	.table-wrap {
		overflow-x: auto;
	}
	table {
		width: 100%;
		border-collapse: collapse;
		font-size: 13px;
	}
	th {
		text-align: left;
		padding: var(--space-sm);
		color: var(--color-text-secondary);
		font-size: 11px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		border-bottom: 0.5px solid var(--color-border);
	}
	td {
		padding: var(--space-sm);
		border-bottom: 0.5px solid var(--color-border-subtle);
	}
	.actions {
		display: flex;
		gap: var(--space-xs);
	}
	.muted {
		color: var(--color-text-muted);
	}
	.error {
		color: var(--color-error);
		font-size: 13px;
	}
	label {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin-bottom: var(--space-sm);
		font-size: 11px;
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
		font-size: 14px;
	}
	.sub {
		color: var(--color-text-secondary);
		font-size: 13px;
	}
</style>
