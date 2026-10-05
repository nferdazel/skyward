<script lang="ts">
	import AppCard from '$lib/core/components/AppCard.svelte';
	import AppButton from '$lib/core/components/AppButton.svelte';
	import AppBadge from '$lib/core/components/AppBadge.svelte';
	import AppEmptyState from '$lib/core/components/AppEmptyState.svelte';
	import AppDialogShell from '$lib/core/components/AppDialogShell.svelte';
	import type { FleetStore } from '../state/fleet-store.svelte';
	import type { AircraftModel, UserFleetAircraft } from '../domain/fleet-models';
	import { isOwned } from '../domain/fleet-models';

	type Props = { store: FleetStore };
	let { store }: Props = $props();

	let tab = $state<'fleet' | 'acquire'>('fleet');
	let dialog = $state<'acquire' | 'repair' | 'sell' | 'seats' | null>(null);
	let selected = $state<UserFleetAircraft | null>(null);
	let selectedModel = $state<AircraftModel | null>(null);
	let busy = $state(false);

	// Form acquire
	let nickname = $state('');
	let economySeats = $state(0);
	let businessSeats = $state(0);
	let firstClassSeats = $state(0);
	let acquireType = $state<'purchase' | 'lease'>('purchase');

	const num = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${num.format(Math.round(n))}`;

	function openAcquire(model: AircraftModel) {
		selectedModel = model;
		nickname = '';
		economySeats = model.capacity;
		businessSeats = 0;
		firstClassSeats = 0;
		dialog = 'acquire';
	}

	async function submitAcquire() {
		if (!selectedModel) return;
		busy = true;
		const params = {
			modelId: selectedModel.id,
			nickname,
			economySeats,
			businessSeats,
			firstClassSeats
		};
		if (acquireType === 'purchase') await store.purchase(params);
		else await store.lease(params);
		busy = false;
		dialog = null;
	}

	function openRepair(a: UserFleetAircraft) {
		selected = a;
		dialog = 'repair';
	}
	function openSell(a: UserFleetAircraft) {
		selected = a;
		dialog = 'sell';
	}
	function openSeats(a: UserFleetAircraft) {
		selected = a;
		economySeats = a.economySeats;
		businessSeats = a.businessSeats;
		firstClassSeats = a.firstClassSeats;
		dialog = 'seats';
	}

	async function confirmRepair() {
		if (!selected) return;
		busy = true;
		await store.repair(selected.id);
		busy = false;
		dialog = null;
	}
	async function confirmSell() {
		if (!selected) return;
		busy = true;
		await store.sell(selected.id);
		busy = false;
		dialog = null;
	}
	async function confirmSeats() {
		if (!selected) return;
		busy = true;
		await store.configureSeats(selected.id, { economySeats, businessSeats, firstClassSeats });
		busy = false;
		dialog = null;
	}

	const fleetCount = $derived(store.state.aircraft.length);
	const ownedCount = $derived(store.state.aircraft.filter(isOwned).length);
</script>

<section>
	<div class="tabs" role="tablist">
		<button
			role="tab"
			aria-selected={tab === 'fleet'}
			class:active={tab === 'fleet'}
			onclick={() => (tab = 'fleet')}
		>
			Armada
		</button>
		<button
			role="tab"
			aria-selected={tab === 'acquire'}
			class:active={tab === 'acquire'}
			onclick={() => (tab = 'acquire')}
		>
			Tambah pesawat
		</button>
	</div>

	{#if store.state.error}
		<p class="error" role="alert">{store.state.error}</p>
	{/if}

	{#if tab === 'fleet'}
		<AppCard>
			<div class="strip">
				<div><span class="k">Total</span><span class="v">{fleetCount}</span></div>
				<div><span class="k">Milik</span><span class="v">{ownedCount}</span></div>
				<div><span class="k">Sewa</span><span class="v">{fleetCount - ownedCount}</span></div>
			</div>

			{#if fleetCount === 0 && !store.state.loading}
				<AppEmptyState
					title="Belum ada pesawat"
					description="Beli atau sewa pesawat untuk mulai terbang."
				/>
			{:else}
				<div class="table-wrap">
					<table>
						<thead>
							<tr>
								<th>Pesawat</th>
								<th>Tipe</th>
								<th>Kondisi</th>
								<th>Status</th>
								<th>Kursi</th>
								<th>Aksi</th>
							</tr>
						</thead>
						<tbody>
							{#each store.state.aircraft as a (a.id)}
								<tr>
									<td>{a.nickname || a.tailNumber || a.model.modelName}</td>
									<td>
										<AppBadge label={a.acquisitionType} tone={isOwned(a) ? 'primary' : 'warning'} />
									</td>
									<td>{Math.round(a.condition)}%</td>
									<td>{a.status}</td>
									<td>
										{a.economySeats + a.businessSeats + a.firstClassSeats || a.model.capacity}
									</td>
									<td class="actions">
										<AppButton text="Perbaiki" variant="secondary" onclick={() => openRepair(a)} />
										<AppButton text="Kursi" variant="secondary" onclick={() => openSeats(a)} />
										{#if a.canBeSold}
											<AppButton text="Jual" variant="secondary" onclick={() => openSell(a)} />
										{/if}
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{/if}
		</AppCard>
	{:else}
		<div class="catalog">
			{#each store.state.catalog as model (model.id)}
				<AppCard>
					<span class="model">{model.manufacturer} {model.modelName}</span>
					<dl>
						<div>
							<dt>Jangkauan</dt>
							<dd>{model.rangeKm} km</dd>
						</div>
						<div>
							<dt>Kapasitas</dt>
							<dd>{model.capacity}</dd>
						</div>
						<div>
							<dt>Beli</dt>
							<dd>{money(model.purchasePrice)}</dd>
						</div>
						<div>
							<dt>Sewa/bln</dt>
							<dd>{money(model.leasePricePerMonth)}</dd>
						</div>
						<div>
							<dt>Tier min</dt>
							<dd>{model.minCreditTier}</dd>
						</div>
					</dl>
					<AppButton text="Beli / Sewa" onclick={() => openAcquire(model)} />
				</AppCard>
			{:else}
				<AppEmptyState title="Katalog kosong" description="Katalog pesawat belum termuat." />
			{/each}
		</div>
	{/if}
</section>

{#if dialog === 'acquire' && selectedModel}
	{@const m = selectedModel}
	<AppDialogShell title="Beli / Sewa pesawat" onclose={() => (dialog = null)}>
		{#snippet children()}
			<p class="sub">{m.manufacturer} {m.modelName}</p>
			<label
				><span>Tipe</span>
				<select bind:value={acquireType}>
					<option value="purchase">Beli</option>
					<option value="lease">Sewa</option>
				</select>
			</label>
			<label><span>Nickname</span><input bind:value={nickname} /></label>
			<label><span>Kursi ekonomi</span><input type="number" bind:value={economySeats} /></label>
			<label><span>Kursi bisnis</span><input type="number" bind:value={businessSeats} /></label>
			<label><span>Kursi first</span><input type="number" bind:value={firstClassSeats} /></label>
		{/snippet}
		{#snippet actions()}
			<AppButton text="Batal" variant="secondary" onclick={() => (dialog = null)} />
			<AppButton
				text={acquireType === 'purchase' ? 'Beli' : 'Sewa'}
				loading={busy}
				onclick={submitAcquire}
			/>
		{/snippet}
	</AppDialogShell>
{/if}

{#if dialog === 'repair' && selected}
	{@const a = selected}
	<AppDialogShell
		title="Perbaiki pesawat"
		subtitle={a.model.modelName}
		onclose={() => (dialog = null)}
	>
		{#snippet children()}
			<p>Biaya perbaikan: <strong>{money(a.repairCost)}</strong></p>
			<p class="sub">Kondisi sekarang {Math.round(a.condition)}%.</p>
		{/snippet}
		{#snippet actions()}
			<AppButton text="Batal" variant="secondary" onclick={() => (dialog = null)} />
			<AppButton text="Perbaiki" loading={busy} onclick={confirmRepair} />
		{/snippet}
	</AppDialogShell>
{/if}

{#if dialog === 'sell' && selected}
	{@const a = selected}
	<AppDialogShell title="Jual pesawat" subtitle={a.model.modelName} onclose={() => (dialog = null)}>
		{#snippet children()}
			<p>Nilai jual: <strong>{money(a.saleValue)}</strong></p>
			{#if a.saleValueNote}<p class="sub">{a.saleValueNote}</p>{/if}
		{/snippet}
		{#snippet actions()}
			<AppButton text="Batal" variant="secondary" onclick={() => (dialog = null)} />
			<AppButton text="Jual" loading={busy} onclick={confirmSell} />
		{/snippet}
	</AppDialogShell>
{/if}

{#if dialog === 'seats' && selected}
	{@const a = selected}
	<AppDialogShell title="Atur kursi" subtitle={a.model.modelName} onclose={() => (dialog = null)}>
		{#snippet children()}
			<label><span>Kursi ekonomi</span><input type="number" bind:value={economySeats} /></label>
			<label><span>Kursi bisnis</span><input type="number" bind:value={businessSeats} /></label>
			<label><span>Kursi first</span><input type="number" bind:value={firstClassSeats} /></label>
		{/snippet}
		{#snippet actions()}
			<AppButton text="Batal" variant="secondary" onclick={() => (dialog = null)} />
			<AppButton text="Simpan" loading={busy} onclick={confirmSeats} />
		{/snippet}
	</AppDialogShell>
{/if}

<style>
	.tabs {
		display: flex;
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
	.strip {
		display: flex;
		gap: var(--space-xl);
		margin-bottom: var(--space-md);
	}
	.k {
		display: block;
		font-size: 11px;
		color: var(--color-text-muted);
		text-transform: uppercase;
		letter-spacing: 0.08em;
	}
	.v {
		font-size: 18px;
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
	.catalog {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
		gap: var(--space-md);
	}
	.model {
		font-weight: 600;
		letter-spacing: 0.04em;
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
	input,
	select {
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
