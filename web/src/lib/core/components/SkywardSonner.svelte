<script lang="ts">
	import type { NotificationStore } from '$lib/features/notification/state/notification-store.svelte';

	/** Toast stack (sonner). Port ringkas dari `SkywardSonner`. */
	type Props = {
		store: NotificationStore;
	};

	let { store }: Props = $props();
</script>

{#if store.toasts.length > 0}
	<div class="sonner" role="status" aria-live="polite">
		{#each store.toasts as toast (toast.id)}
			<button class="toast {toast.type}" onclick={() => store.dismiss(toast.id)}>
				<span class="title">{toast.title}</span>
				{#if toast.message}
					<span class="message">{toast.message}</span>
				{/if}
			</button>
		{/each}
	</div>
{/if}

<style>
	.sonner {
		position: fixed;
		bottom: var(--space-lg);
		right: var(--space-lg);
		width: 360px;
		max-width: calc(100vw - 2 * var(--space-lg));
		display: flex;
		flex-direction: column;
		gap: var(--space-sm);
		z-index: 200;
	}
	.toast {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		text-align: left;
		background: var(--color-surface-3);
		border: 1px solid var(--color-border);
		border-left-width: 3px;
		border-radius: var(--radius-default);
		padding: var(--space-md);
		color: var(--color-text-primary);
		font-family: var(--font-sans);
		cursor: pointer;
		box-shadow: 0 6px 20px rgb(0 0 0 / 0.4);
	}
	.toast.info {
		border-left-color: var(--color-accent);
	}
	.toast.success {
		border-left-color: var(--color-success);
	}
	.toast.warning {
		border-left-color: var(--color-warning);
	}
	.toast.error {
		border-left-color: var(--color-error);
	}
	.title {
		font-weight: 600;
		font-size: 13px;
	}
	.message {
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	@media (prefers-reduced-motion: no-preference) {
		.toast {
			animation: toast-in var(--motion-base) var(--motion-ease);
		}
	}
	@keyframes toast-in {
		from {
			opacity: 0;
			transform: translateY(8px);
		}
		to {
			opacity: 1;
			transform: none;
		}
	}
</style>
