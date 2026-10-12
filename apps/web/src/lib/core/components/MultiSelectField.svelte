<script lang="ts">
	import AppDialogShell from './AppDialogShell.svelte';
	import TactileButton from './TactileButton.svelte';

	/**
	 * Multi-select filter field: a summary button that opens a checkbox picker.
	 * The picker edits a working copy, so a stray tap cannot change the filter;
	 * only APPLY commits it. Port dari Flutter `AppMultiSelectField`.
	 */
	type Props = {
		label: string;
		options: string[];
		selected: string[];
		onchange: (values: string[]) => void;
	};
	let { label, options, selected, onchange }: Props = $props();

	let open = $state(false);
	let working = $state<string[]>([]);
	let field = $state<HTMLButtonElement | null>(null);

	const summary = $derived(
		selected.length === 0
			? 'ALL'
			: selected.length === 1
				? selected[0].toUpperCase()
				: `${selected.length} SELECTED`
	);

	function openPicker() {
		working = [...selected];
		open = true;
	}

	/** Tutup picker dan kembalikan fokus ke field — dialog yang hilang tanpa
	 * mengembalikan fokus melempar pengguna keyboard ke awal halaman. */
	function close() {
		open = false;
		field?.focus();
	}

	function toggle(option: string) {
		working = working.includes(option)
			? working.filter((value) => value !== option)
			: [...working, option];
	}

	function apply() {
		onchange(working);
		close();
	}

	function clear() {
		onchange([]);
		close();
	}
</script>

<button bind:this={field} type="button" class="field" aria-haspopup="dialog" onclick={openPicker}>
	<span class="stack">
		<span class="label">{label}</span>
		<span class="summary">{summary}</span>
	</span>
	<svg class="chevron" viewBox="0 0 12 12" aria-hidden="true">
		<path d="M2 4.25 6 8.25 10 4.25" fill="none" stroke="currentColor" stroke-width="1.5" />
	</svg>
</button>

{#if open}
	<AppDialogShell title={label} onclose={close}>
		<ul class="options">
			{#each options as option (option)}
				<li>
					<label>
						<input
							type="checkbox"
							checked={working.includes(option)}
							onchange={() => toggle(option)}
						/>
						<span>{option.toUpperCase()}</span>
					</label>
				</li>
			{:else}
				<li class="empty">No options available.</li>
			{/each}
		</ul>
		{#snippet actions()}
			<div class="dialog-actions">
				<TactileButton text="Clear" type="secondary" onclick={clear} />
				<span class="right">
					<TactileButton text="Cancel" type="secondary" onclick={close} />
					<TactileButton text="Apply" type="primary" onclick={apply} />
				</span>
			</div>
		{/snippet}
	</AppDialogShell>
{/if}

<style>
	.field {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
		width: 100%;
		padding: var(--space-sm) var(--space-md);
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		color: var(--color-text-primary);
		font-family: var(--font-sans);
		text-align: left;
		cursor: pointer;
		transition: border-color var(--motion-fast) var(--motion-ease);
	}
	.field:hover {
		border-color: var(--color-border-highlight);
	}
	.stack {
		display: flex;
		flex-direction: column;
		gap: 2px;
		flex: 1;
		min-width: 0;
	}
	.label {
		font-size: 10px;
		letter-spacing: 0.06em;
		text-transform: uppercase;
		color: var(--color-text-secondary);
	}
	.summary {
		font-size: 12px;
		font-weight: 600;
		letter-spacing: 0.04em;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}
	.chevron {
		width: 12px;
		height: 12px;
		flex: none;
		color: var(--color-accent);
	}
	.options {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin: 0;
		padding: 0;
		list-style: none;
	}
	.options label {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
		padding: var(--space-xs) 0;
		font-size: 12px;
		letter-spacing: 0.04em;
		cursor: pointer;
	}
	.options input {
		accent-color: var(--color-accent);
		width: 15px;
		height: 15px;
		cursor: pointer;
	}
	.empty {
		font-size: 12px;
		color: var(--color-text-muted);
	}
	.dialog-actions {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: var(--space-sm);
		width: 100%;
	}
	.right {
		display: flex;
		gap: var(--space-sm);
	}
</style>
