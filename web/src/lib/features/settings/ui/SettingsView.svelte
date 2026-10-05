<script lang="ts">
	import { untrack } from 'svelte';
	import AppCard from '$lib/core/components/AppCard.svelte';
	import AppButton from '$lib/core/components/AppButton.svelte';
	import AppDialogShell from '$lib/core/components/AppDialogShell.svelte';
	import type { SettingsStore } from '../state/settings-store.svelte';
	import type { AuthStore } from '$lib/features/auth/state/auth-store.svelte';

	type Props = { store: SettingsStore; auth: AuthStore };
	let { store, auth }: Props = $props();

	// Nilai awal form diambil sekali (bukan reaktif): user bisa mengedit, dan
	// kita tidak mau editan tertimpa saat store berubah.
	const initial = untrack(() => ({
		companyName: auth.user?.companyName ?? '',
		hqAirportIata: auth.user?.hqAirportIata ?? '',
		groundingThreshold: auth.user?.autoGroundingThreshold ?? 40
	}));

	let companyName = $state(initial.companyName);
	let hqAirportIata = $state(initial.hqAirportIata);
	let groundingThreshold = $state(initial.groundingThreshold);
	let busy = $state(false);
	let confirm = $state<'reset' | 'delete' | null>(null);
	let message = $state<string | null>(null);

	const airportCodes = $derived(store.state.airports.map((a) => a.iata));

	async function save() {
		busy = true;
		const ok = await store.save({
			companyName,
			hqAirportIata,
			autoGroundingThreshold: groundingThreshold
		});
		busy = false;
		message = ok ? 'Pengaturan disimpan.' : (store.state.error ?? 'Gagal menyimpan.');
	}

	async function doReset() {
		busy = true;
		const ok = await store.reset();
		busy = false;
		confirm = null;
		message = ok ? 'Maskapai direset.' : (store.state.error ?? 'Gagal reset.');
	}

	async function doDelete() {
		busy = true;
		const ok = await store.deleteAccount();
		busy = false;
		confirm = null;
		if (ok) auth.logout();
		else message = store.state.error ?? 'Gagal menghapus akun.';
	}
</script>

<section>
	<h2>Pengaturan</h2>

	{#if message}
		<p class="notice" role="status">{message}</p>
	{/if}

	<AppCard>
		<h3>Profil maskapai</h3>
		<label><span>Nama maskapai</span><input bind:value={companyName} /></label>
		<label>
			<span>Bandara pusat (IATA)</span>
			<input bind:value={hqAirportIata} list="airports" placeholder="SIN" />
			<datalist id="airports">
				{#each airportCodes as code (code)}
					<option value={code}></option>
				{/each}
			</datalist>
		</label>
		<label>
			<span>Ambang auto-grounding (%)</span>
			<input type="number" bind:value={groundingThreshold} />
		</label>
		<AppButton text="Simpan" loading={busy} onclick={companyName.trim() ? save : undefined} />
	</AppCard>

	<AppCard>
		<h3>Zona berbahaya</h3>
		<p class="muted">
			Reset mengembalikan maskapai ke kondisi awal. Hapus akun tidak bisa dibatalkan.
		</p>
		<div class="danger">
			<AppButton text="Reset maskapai" variant="secondary" onclick={() => (confirm = 'reset')} />
			<AppButton text="Hapus akun" variant="secondary" onclick={() => (confirm = 'delete')} />
		</div>
	</AppCard>
</section>

{#if confirm === 'reset'}
	<AppDialogShell title="Reset maskapai?" onclose={() => (confirm = null)}>
		{#snippet children()}
			<p class="muted">Semua progres (armada, rute, keuangan) akan dikembalikan ke awal.</p>
		{/snippet}
		{#snippet actions()}
			<AppButton text="Batal" variant="secondary" onclick={() => (confirm = null)} />
			<AppButton text="Reset" loading={busy} onclick={doReset} />
		{/snippet}
	</AppDialogShell>
{/if}

{#if confirm === 'delete'}
	<AppDialogShell title="Hapus akun?" onclose={() => (confirm = null)}>
		{#snippet children()}
			<p class="muted">Tindakan ini permanen dan tidak bisa dibatalkan.</p>
		{/snippet}
		{#snippet actions()}
			<AppButton text="Batal" variant="secondary" onclick={() => (confirm = null)} />
			<AppButton text="Hapus" loading={busy} onclick={doDelete} />
		{/snippet}
	</AppDialogShell>
{/if}

<style>
	h2 {
		margin: 0 0 var(--space-md);
		font-size: 16px;
		letter-spacing: 0.06em;
		text-transform: uppercase;
	}
	h3 {
		margin: 0 0 var(--space-sm);
		font-size: 12px;
		letter-spacing: 0.06em;
		text-transform: uppercase;
		color: var(--color-text-secondary);
	}
	section :global(.app-card) {
		margin-bottom: var(--space-md);
	}
	label {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin-bottom: var(--space-md);
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
	.muted {
		color: var(--color-text-muted);
		font-size: 12px;
	}
	.notice {
		color: var(--color-success);
		font-size: 13px;
	}
	.danger {
		display: flex;
		gap: var(--space-sm);
		margin-top: var(--space-sm);
	}
</style>
