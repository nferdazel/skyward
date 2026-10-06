<script lang="ts">
	import AppBadge from './AppBadge.svelte';
	import type { NotificationStore } from '$lib/features/notification/state/notification-store.svelte';

	/**
	 * Notification panel shown from the HUD bell. Lists queued notifications
	 * (excluding world events, which are persistent status). Ported from the
	 * Flutter notification panel.
	 */
	type Props = {
		store: NotificationStore;
		onclose: () => void;
	};
	let { store, onclose }: Props = $props();

	function tone(type: string): 'primary' | 'success' | 'warning' | 'error' | 'secondary' {
		if (type === 'success') return 'success';
		if (type === 'warning') return 'warning';
		if (type === 'error') return 'error';
		if (type === 'info') return 'primary';
		return 'secondary';
	}
</script>

<div class="panel" role="dialog" aria-label="Notifications">
	<div class="head">
		<span class="title">Notifications</span>
		<button class="close" aria-label="Close" onclick={onclose}>×</button>
	</div>

	{#if store.state.items.length === 0}
		<p class="empty">No notifications.</p>
	{:else}
		<ul>
			{#each store.state.items as n (n.id)}
				<li class="row">
					<div class="row-main">
						<span class="row-title">{n.title}</span>
						{#if n.message}<span class="row-body">{n.message}</span>{/if}
					</div>
					<div class="row-side">
						<AppBadge label={n.type} tone={tone(n.type)} />
						<button class="dismiss" aria-label="Dismiss" onclick={() => store.dismiss(n.id)}
							>×</button
						>
					</div>
				</li>
			{/each}
		</ul>
		<button class="clear" onclick={() => store.clear()}>Clear all</button>
	{/if}
</div>

<style>
	.panel {
		position: absolute;
		top: calc(100% + var(--space-xs));
		right: 0;
		width: 340px;
		max-width: calc(100vw - 2 * var(--space-md));
		z-index: 120;
		background: var(--color-surface-3);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		box-shadow: 0 12px 32px rgb(0 0 0 / 0.5);
		overflow: hidden;
	}
	.head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: var(--space-sm) var(--space-md);
		background: var(--color-surface-2);
		border-bottom: 1px solid var(--color-border-subtle);
	}
	.title {
		font-size: 11px;
		font-weight: 600;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--color-text-secondary);
	}
	.close,
	.dismiss {
		background: none;
		border: none;
		color: var(--color-text-secondary);
		font-size: 16px;
		cursor: pointer;
		line-height: 1;
	}
	.close:hover,
	.dismiss:hover {
		color: var(--color-text-primary);
	}
	ul {
		list-style: none;
		margin: 0;
		padding: 0;
		max-height: 360px;
		overflow-y: auto;
	}
	.row {
		display: flex;
		align-items: flex-start;
		gap: var(--space-sm);
		padding: var(--space-sm) var(--space-md);
		border-bottom: 0.5px solid var(--color-border-subtle);
	}
	.row-main {
		flex: 1;
		min-width: 0;
		display: flex;
		flex-direction: column;
		gap: 2px;
	}
	.row-title {
		font-size: 13px;
		font-weight: 600;
	}
	.row-body {
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.row-side {
		display: flex;
		align-items: center;
		gap: var(--space-xs);
	}
	.empty {
		margin: 0;
		padding: var(--space-lg);
		text-align: center;
		font-size: 13px;
		color: var(--color-text-muted);
	}
	.clear {
		width: 100%;
		padding: var(--space-sm);
		background: var(--color-surface-2);
		border: none;
		border-top: 1px solid var(--color-border-subtle);
		color: var(--color-text-secondary);
		font-size: 12px;
		cursor: pointer;
	}
	.clear:hover {
		color: var(--color-text-primary);
	}
</style>
