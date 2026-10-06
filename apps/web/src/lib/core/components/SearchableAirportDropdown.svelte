<script lang="ts">
	import { untrack } from 'svelte';
	import type { Airport } from '$lib/features/routes/domain/airport';

	/**
	 * Searchable airport picker. Ported from Flutter `SearchableAirportDropdown`:
	 * filters by IATA / city / country / name; selection displays
	 * `[IATA] CITY (COUNTRY)`.
	 */
	type Props = {
		airports: Airport[];
		value: Airport | null;
		onselect: (airport: Airport | null) => void;
		label?: string;
		placeholder?: string;
	};

	let {
		airports,
		value,
		onselect,
		label = 'Airport',
		placeholder = 'Search IATA / city'
	}: Props = $props();

	// Seed once from the initial value; the user edits the query afterwards.
	let query = $state(untrack(() => (value ? display(value) : '')));
	let open = $state(false);

	function display(a: Airport): string {
		return `[${a.iata}] ${a.city} (${a.country})`.toUpperCase();
	}

	const filtered = $derived.by(() => {
		const q = query.trim().toLowerCase();
		if (!q) return airports.slice(0, 40);
		return airports
			.filter(
				(a) =>
					a.iata.toLowerCase().includes(q) ||
					a.city.toLowerCase().includes(q) ||
					a.country.toLowerCase().includes(q) ||
					a.name.toLowerCase().includes(q)
			)
			.slice(0, 40);
	});

	function pick(a: Airport) {
		query = display(a);
		open = false;
		onselect(a);
	}
	function clear() {
		query = '';
		onselect(null);
	}

	function oninput() {
		open = true;
		// Free-text: clear the committed value until a row is picked.
		onselect(null);
	}
</script>

<div class="field">
	<span class="k">{label}</span>
	<div class="input-wrap">
		<input
			class="control"
			{placeholder}
			bind:value={query}
			{oninput}
			onfocus={() => (open = true)}
			onblur={() => setTimeout(() => (open = false), 120)}
		/>
		{#if query}
			<button class="clear" aria-label="Clear" onclick={clear}>×</button>
		{/if}
	</div>
	{#if open && filtered.length > 0}
		<ul class="menu" role="listbox">
			{#each filtered as a (a.iata)}
				<li>
					<button role="option" aria-selected={value?.iata === a.iata} onclick={() => pick(a)}>
						<span class="iata">{a.iata}</span>
						<span class="city">{a.city}</span>
						<span class="country">{a.country}</span>
					</button>
				</li>
			{/each}
		</ul>
	{/if}
</div>

<style>
	.field {
		position: relative;
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
	}
	.k {
		font-size: 11px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--color-text-secondary);
	}
	.input-wrap {
		position: relative;
	}
	.control {
		width: 100%;
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		color: var(--color-text-primary);
		padding: var(--space-sm);
		font-size: 14px;
	}
	.control:focus {
		outline: none;
		border-color: var(--color-accent);
	}
	.clear {
		position: absolute;
		right: var(--space-xs);
		top: 50%;
		transform: translateY(-50%);
		background: none;
		border: none;
		color: var(--color-text-secondary);
		font-size: 18px;
		cursor: pointer;
		padding: 0 var(--space-xs);
	}
	.menu {
		position: absolute;
		top: 100%;
		left: 0;
		right: 0;
		z-index: 40;
		margin: var(--space-xs) 0 0;
		padding: var(--space-xs);
		list-style: none;
		max-height: 240px;
		overflow-y: auto;
		background: var(--color-surface-3);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		box-shadow: 0 8px 24px rgb(0 0 0 / 0.4);
	}
	.menu button {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
		width: 100%;
		padding: var(--space-sm);
		background: none;
		border: none;
		border-radius: var(--radius-tight);
		color: var(--color-text-primary);
		cursor: pointer;
		text-align: left;
		font: inherit;
	}
	.menu button:hover {
		background: var(--color-surface-active);
	}
	.iata {
		font-weight: 700;
		color: var(--color-accent);
		min-width: 32px;
	}
	.city {
		flex: 1;
	}
	.country {
		font-size: 11px;
		color: var(--color-text-muted);
	}
</style>
