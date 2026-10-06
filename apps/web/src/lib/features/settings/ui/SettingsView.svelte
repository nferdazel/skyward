<script lang="ts">
	import { untrack } from 'svelte';
	import CraftCard from '$lib/core/components/CraftCard.svelte';
	import TactileButton from '$lib/core/components/TactileButton.svelte';
	import AppDialogShell from '$lib/core/components/AppDialogShell.svelte';
	import type { SettingsStore } from '../state/settings-store.svelte';
	import type { AppUser } from '$lib/features/auth/domain/user';

	/**
	 * Settings view. Ported from Flutter `SettingsView`: profile form (branding),
	 * game settings (auto-grounding + seat preset), and danger zone (reset /
	 * delete account with typed confirmation).
	 */
	type Props = {
		store: SettingsStore;
		user: AppUser | null;
		onsaved?: () => void;
		ondeleted: () => void;
	};
	let { store, user, onsaved, ondeleted }: Props = $props();

	const seed = untrack(() => ({
		companyName: user?.companyName ?? '',
		hq: user?.hqAirportIata ?? 'SIN',
		threshold: user?.autoGroundingThreshold ?? 40
	}));

	let companyName = $state(seed.companyName);
	let hq = $state(seed.hq);
	let threshold = $state(seed.threshold);
	let busy = $state(false);
	let message = $state<string | null>(null);
	let confirm = $state<'reset' | 'delete' | null>(null);
	let deleteConfirmText = $state('');

	const airportCodes = $derived(store.state.airports.map((a) => a.iata));

	async function save() {
		busy = true;
		const ok = await store.save({
			companyName: companyName.trim(),
			hqAirportIata: hq,
			autoGroundingThreshold: threshold
		});
		busy = false;
		message = ok ? 'Settings saved.' : (store.state.error ?? 'Failed to save.');
		if (ok) onsaved?.();
	}

	async function doReset() {
		busy = true;
		const ok = await store.reset();
		busy = false;
		confirm = null;
		message = ok ? 'Airline reset.' : (store.state.error ?? 'Reset failed.');
	}

	async function doDelete() {
		if (deleteConfirmText.trim().toUpperCase() !== 'DELETE') return;
		busy = true;
		const ok = await store.deleteAccount();
		busy = false;
		confirm = null;
		if (ok) ondeleted();
		else message = store.state.error ?? 'Failed to delete account.';
	}
</script>

<section>
	<h2>Settings</h2>

	{#if message}
		<p class="notice" role="status">{message}</p>
	{/if}

	<CraftCard>
		<div class="card-pad">
			<span class="k">Branding</span>
			<label class="field">
				<span>Company name</span>
				<input bind:value={companyName} />
			</label>
			<label class="field">
				<span>HQ airport (IATA)</span>
				<input bind:value={hq} list="airports" placeholder="SIN" />
				<datalist id="airports">
					{#each airportCodes as code (code)}<option value={code}></option>{/each}
				</datalist>
			</label>
			<TactileButton
				text="Save brand"
				type="primary"
				loading={busy}
				width="100%"
				onclick={companyName.trim() ? save : undefined}
			/>
		</div>
	</CraftCard>

	<CraftCard>
		<div class="card-pad">
			<span class="k">Flight operations</span>
			<span class="muted"
				>Auto-grounding threshold: aircraft below this condition are grounded automatically.</span
			>
			<div class="threshold">
				<input class="slider" type="range" min="30" max="80" step="5" bind:value={threshold} />
				<span class="th-val tnum">{threshold}%</span>
			</div>
			<TactileButton text="Save operations" type="primary" loading={busy} onclick={save} />
		</div>
	</CraftCard>

	<CraftCard>
		<div class="card-pad">
			<span class="k">Danger zone</span>
			<span class="muted">
				Reset restores the airline to its initial state. Deleting the account cannot be undone.
			</span>
			<div class="danger">
				<TactileButton
					text="Reset airline"
					type="destructive"
					onclick={() => (confirm = 'reset')}
				/>
				<TactileButton
					text="Delete account"
					type="destructive"
					onclick={() => {
						deleteConfirmText = '';
						confirm = 'delete';
					}}
				/>
			</div>
		</div>
	</CraftCard>
</section>

{#if confirm === 'reset'}
	<AppDialogShell title="Reset airline?" onclose={() => (confirm = null)}>
		{#snippet children()}
			<p class="muted">All progress (fleet, routes, finances) will be reset.</p>
		{/snippet}
		{#snippet actions()}
			<TactileButton text="Cancel" type="secondary" onclick={() => (confirm = null)} />
			<TactileButton text="Reset" type="destructive" loading={busy} onclick={doReset} />
		{/snippet}
	</AppDialogShell>
{/if}

{#if confirm === 'delete'}
	<AppDialogShell title="Delete account?" onclose={() => (confirm = null)}>
		{#snippet children()}
			<p class="muted">This action is permanent and cannot be undone. Type DELETE to confirm.</p>
			<input class="danger-input" bind:value={deleteConfirmText} placeholder="DELETE" />
		{/snippet}
		{#snippet actions()}
			<TactileButton text="Cancel" type="secondary" onclick={() => (confirm = null)} />
			<TactileButton
				text="Delete"
				type="destructive"
				loading={busy}
				onclick={deleteConfirmText.trim().toUpperCase() === 'DELETE' ? doDelete : undefined}
			/>
		{/snippet}
	</AppDialogShell>
{/if}

<style>
	section {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
		max-width: 560px;
	}
	h2 {
		margin: 0;
		font-size: 16px;
		letter-spacing: 0.06em;
		text-transform: uppercase;
	}
	.card-pad {
		display: flex;
		flex-direction: column;
		gap: var(--space-sm);
	}
	.k {
		font-size: 11px;
		font-weight: 600;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		color: var(--color-text-muted);
	}
	.muted {
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.field {
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
	.threshold {
		display: flex;
		align-items: center;
		gap: var(--space-md);
	}
	.slider {
		flex: 1;
		accent-color: var(--color-accent);
	}
	.th-val {
		font-size: 16px;
		font-weight: 700;
	}
	.danger {
		display: flex;
		gap: var(--space-sm);
		margin-top: var(--space-xs);
	}
	.notice {
		color: var(--color-success);
		font-size: 13px;
	}
	.danger-input {
		width: 100%;
		margin-top: var(--space-sm);
	}
</style>
