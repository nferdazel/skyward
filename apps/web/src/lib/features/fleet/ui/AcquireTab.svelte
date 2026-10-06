<script lang="ts">
	import CraftCard from '$lib/core/components/CraftCard.svelte';
	import TactileButton from '$lib/core/components/TactileButton.svelte';
	import SlideOverDrawer from '$lib/core/components/SlideOverDrawer.svelte';
	import type { FleetStore } from '../state/fleet-store.svelte';
	import type { AircraftModel } from '../domain/fleet-models';

	/**
	 * Acquire-aircraft tab. Ported from Flutter fleet acquire tab: a catalog of
	 * models with a slide-over purchase/lease form.
	 */
	type Props = {
		store: FleetStore;
		/** Player's current credit tier, for gating models by `minCreditTier`. */
		creditTier?: string | null;
		/** Finance a model with a loan (down payment + term). */
		onFinance?: (model: AircraftModel, downPaymentPct: number, termMonths: number) => Promise<void>;
	};
	let { store, creditTier = null, onFinance }: Props = $props();

	/** Matches the server's creditTierRank (unknown → 0). */
	function tierRank(tier: string | null | undefined): number {
		switch (tier) {
			case 'Platinum':
				return 4;
			case 'Gold':
				return 3;
			case 'Silver':
				return 2;
			case 'Standard':
				return 1;
			default:
				return 0;
		}
	}
	const playerRank = $derived(tierRank(creditTier));
	function isTierLocked(model: AircraftModel): boolean {
		return playerRank < tierRank(model.minCreditTier);
	}

	let selected = $state<AircraftModel | null>(null);
	let mode = $state<'purchase' | 'lease' | 'finance'>('purchase');
	let nickname = $state('');
	let eco = $state(0);
	let bus = $state(0);
	let first = $state(0);
	let downPct = $state(0.2);
	let termMonths = $state(60);
	let busy = $state(false);

	const fmt = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${fmt.format(Math.round(n))}`;

	function open(model: AircraftModel) {
		selected = model;
		mode = 'purchase';
		nickname = '';
		eco = model.capacity;
		bus = 0;
		first = 0;
	}

	async function submit() {
		if (!selected) return;
		busy = true;
		if (mode === 'finance') {
			await onFinance?.(selected, downPct, termMonths);
		} else {
			const params = {
				modelId: selected.id,
				nickname,
				economySeats: eco,
				businessSeats: bus,
				firstClassSeats: first
			};
			if (mode === 'purchase') await store.purchase(params);
			else await store.lease(params);
		}
		busy = false;
		selected = null;
	}
</script>

<div class="catalog">
	{#each store.state.catalog as model (model.id)}
		<CraftCard>
			<div class="head">
				<span class="name">{model.manufacturer} {model.modelName}</span>
				<span class="type">{model.type}</span>
			</div>
			<dl>
				<div>
					<dt>Range</dt>
					<dd class="tnum">{model.rangeKm} km</dd>
				</div>
				<div>
					<dt>Capacity</dt>
					<dd class="tnum">{model.capacity}</dd>
				</div>
				<div>
					<dt>Buy</dt>
					<dd class="tnum">{money(model.purchasePrice)}</dd>
				</div>
				<div>
					<dt>Lease / mo</dt>
					<dd class="tnum">{money(model.leasePricePerMonth)}</dd>
				</div>
				<div>
					<dt>Min tier</dt>
					<dd>{model.minCreditTier}</dd>
				</div>
			</dl>
			{#if isTierLocked(model)}
				<p class="locked">Requires credit tier {model.minCreditTier}</p>
				<TactileButton text="Locked" type="secondary" />
			{:else}
				<TactileButton text="Acquire" type="primary" onclick={() => open(model)} />
			{/if}
		</CraftCard>
	{:else}
		<CraftCard><p class="muted">Catalog is empty.</p></CraftCard>
	{/each}
</div>

{#if selected}
	{@const m = selected}
	<SlideOverDrawer
		title="Acquire aircraft"
		subtitle="{m.manufacturer} {m.modelName}"
		onclose={() => (selected = null)}
	>
		<div class="form">
			<div class="modes">
				<button class:active={mode === 'purchase'} onclick={() => (mode = 'purchase')}>Buy</button>
				<button class:active={mode === 'lease'} onclick={() => (mode = 'lease')}>Lease</button>
				{#if onFinance}
					<button class:active={mode === 'finance'} onclick={() => (mode = 'finance')}
						>Finance</button
					>
				{/if}
			</div>
			<label><span>Nickname</span><input bind:value={nickname} /></label>
			<label><span>Economy seats</span><input type="number" min="0" bind:value={eco} /></label>
			<label><span>Business seats</span><input type="number" min="0" bind:value={bus} /></label>
			<label><span>First seats</span><input type="number" min="0" bind:value={first} /></label>
			{#if mode === 'finance'}
				<label
					><span>Down payment {Math.round(downPct * 100)}%</span><input
						type="range"
						min="0.1"
						max="0.9"
						step="0.05"
						bind:value={downPct}
						aria-label="Down payment percent"
					/></label
				>
				<label
					><span>Term (months)</span><input
						type="number"
						min="12"
						max="120"
						bind:value={termMonths}
					/></label
				>
				<p class="cost">
					Down {money(m.purchasePrice * downPct)} · financed {money(
						m.purchasePrice * (1 - downPct)
					)}
				</p>
			{:else}
				<p class="cost">
					{mode === 'purchase'
						? `Buy price ${money(m.purchasePrice)}`
						: `Lease ${money(m.leasePricePerMonth)} / month`}
				</p>
			{/if}
		</div>
		{#snippet bottomActions()}
			<div class="actions">
				<TactileButton text="Cancel" type="secondary" onclick={() => (selected = null)} />
				<TactileButton
					text={mode === 'purchase' ? 'Buy' : mode === 'lease' ? 'Lease' : 'Finance'}
					type="primary"
					loading={busy}
					onclick={submit}
				/>
			</div>
		{/snippet}
	</SlideOverDrawer>
{/if}

<style>
	.catalog {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
		gap: var(--space-md);
	}
	.head {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
		gap: var(--space-sm);
	}
	.name {
		font-weight: 600;
	}
	.type {
		font-size: 10px;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.08em;
	}
	dl {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin: var(--space-sm) 0;
	}
	dl > div {
		display: flex;
		justify-content: space-between;
	}
	dt {
		color: var(--color-text-muted);
		font-size: 11px;
	}
	dd {
		margin: 0;
		font-size: 13px;
	}
	.muted {
		color: var(--color-text-muted);
		font-size: 13px;
	}
	.locked {
		margin: 0;
		font-size: 12px;
		color: var(--color-warning);
	}
	.form {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
	}
	.modes {
		display: flex;
		gap: var(--space-sm);
	}
	.modes button {
		flex: 1;
		padding: var(--space-sm);
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		color: var(--color-text-secondary);
		cursor: pointer;
		font-family: var(--font-sans);
		font-weight: 600;
		font-size: 12px;
	}
	.modes button.active {
		background: var(--color-accent-subtle);
		border-color: var(--color-accent);
		color: var(--color-accent);
	}
	label {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
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
		text-transform: none;
	}
	.cost {
		color: var(--color-text-secondary);
		font-size: 13px;
	}
	.actions {
		display: flex;
		gap: var(--space-sm);
	}
</style>
