<script lang="ts">
	import type { Snippet } from 'svelte';

	/** Cangkang tabel dengan header dan body. Port ringkas `AppTableShell`. */
	type Props = {
		columns: string[];
		children: Snippet;
		empty?: Snippet;
		isEmpty?: boolean;
	};

	let { columns, children, empty, isEmpty = false }: Props = $props();
</script>

<div class="table-shell">
	<table>
		<thead>
			<tr>
				{#each columns as col (col)}
					<th scope="col">{col}</th>
				{/each}
			</tr>
		</thead>
		<tbody>
			{#if isEmpty}
				<tr>
					<td class="empty" colspan={columns.length}>
						{#if empty}
							{@render empty()}
						{:else}
							Tidak ada data.
						{/if}
					</td>
				</tr>
			{:else}
				{@render children()}
			{/if}
		</tbody>
	</table>
</div>

<style>
	.table-shell {
		overflow-x: auto;
		border: 0.5px solid var(--color-border);
		border-radius: var(--radius-default);
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
		font-size: 11px;
		font-weight: 600;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		border-bottom: 0.5px solid var(--color-border);
		white-space: nowrap;
	}
	:global(.table-shell td) {
		padding: var(--space-sm) var(--space-md);
		border-bottom: 0.5px solid var(--color-border-subtle);
	}
	:global(.table-shell tbody tr:hover td) {
		background: var(--color-surface-active);
	}
	.empty {
		text-align: center;
		color: var(--color-text-muted);
		padding: var(--space-xl);
	}
</style>
