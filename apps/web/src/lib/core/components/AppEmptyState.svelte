<script lang="ts">
	import AppButton from './AppButton.svelte';
	import AppCard from './AppCard.svelte';

	/**
	 * Placeholder shown when no data is available. Ported from Flutter
	 * `AppEmptyState`. `icon` is a snippet so callers pass their own SVG.
	 */
	import type { Snippet } from 'svelte';

	type Props = {
		title: string;
		description: string;
		icon?: Snippet;
		actionLabel?: string;
		onAction?: () => void;
	};

	let { title, description, icon, actionLabel, onAction }: Props = $props();
</script>

<AppCard>
	<div class="empty" aria-label="Empty state: {title}">
		{#if icon}
			<span class="icon">{@render icon()}</span>
		{/if}
		<span class="title">{title}</span>
		<span class="description">{description}</span>
		{#if actionLabel}
			<div class="action">
				<AppButton text={actionLabel} onclick={onAction} />
			</div>
		{/if}
	</div>
</AppCard>

<style>
	.empty {
		display: flex;
		flex-direction: column;
		align-items: center;
		text-align: center;
		width: 100%;
		padding: var(--space-xxxxl) 0;
	}

	.icon {
		display: inline-flex;
		color: var(--color-text-muted);
		margin-bottom: var(--space-md);
	}

	.title {
		font-size: 12px;
		font-weight: 600;
		letter-spacing: 0.06em;
		color: var(--color-text-primary);
	}

	.description {
		margin-top: var(--space-xs);
		font-size: 13px;
		color: var(--color-text-secondary);
	}

	.action {
		margin-top: var(--space-lg);
	}
</style>
