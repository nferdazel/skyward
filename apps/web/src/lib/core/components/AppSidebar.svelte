<script lang="ts">
	import SkywardLogo from './SkywardLogo.svelte';

	/**
	 * Vertical navigation rail (52px). Ported from Flutter `DashboardSidebar`.
	 * Items show an active pill with a 3px left accent border; a divider splits
	 * the operations group from Financials. Logout sits at the bottom.
	 */
	export type NavKey = 'dashboard' | 'fleet' | 'routes' | 'financials' | 'rankings' | 'settings';

	type Props = {
		active: NavKey;
		onselect: (key: NavKey) => void;
		onlogout: () => void;
	};

	let { active, onselect, onlogout }: Props = $props();

	const items: { key: NavKey; label: string; icon: string }[] = [
		{
			key: 'dashboard',
			label: 'Dashboard',
			icon: 'M3 3h7v7H3zM14 3h7v4h-7zM14 10h7v11h-7zM3 13h7v8H3z'
		},
		{
			key: 'fleet',
			label: 'Fleet',
			icon: 'M21 16v-2l-8-5V3.5a1.5 1.5 0 0 0-3 0V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5z'
		},
		{
			key: 'routes',
			label: 'Routes',
			icon: 'M12 2a7 7 0 0 0-7 7c0 5 7 13 7 13s7-8 7-13a7 7 0 0 0-7-7zm0 9.5A2.5 2.5 0 1 1 12 6a2.5 2.5 0 0 1 0 5.5z'
		},
		{
			key: 'financials',
			label: 'Financials',
			icon: 'M6 2h9l5 5v15H6zm8 1.5V8h4.5zM8 12h8v2H8zm0 4h8v2H8z'
		},
		{ key: 'rankings', label: 'Rankings', icon: 'M4 20h4V10H4zm6 0h4V4h-4zm6 0h4v-7h-4z' },
		{
			key: 'settings',
			label: 'Settings',
			icon: 'M12 15.5A3.5 3.5 0 1 1 12 8a3.5 3.5 0 0 1 0 7.5zM19 12a7 7 0 0 0-.1-1.2l2-1.6-2-3.4-2.4 1a7 7 0 0 0-2-1.2L14 2h-4l-.5 2.6a7 7 0 0 0-2 1.2l-2.4-1-2 3.4 2 1.6A7 7 0 0 0 5 12c0 .4 0 .8.1 1.2l-2 1.6 2 3.4 2.4-1a7 7 0 0 0 2 1.2L10 22h4l.5-2.6a7 7 0 0 0 2-1.2l2.4 1 2-3.4-2-1.6c.1-.4.1-.8.1-1.2z'
		}
	];
</script>

<nav class="rail" aria-label="Primary">
	<div class="logo" title="Skyward Command Center">
		<SkywardLogo size={32} showBackground />
	</div>

	<ul>
		{#each items as item, i (item.key)}
			{#if i === 3}
				<li class="divider" aria-hidden="true"></li>
			{/if}
			<li>
				<button
					class="item"
					class:active={active === item.key}
					aria-current={active === item.key ? 'page' : undefined}
					title={item.label}
					onclick={() => onselect(item.key)}
				>
					<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
						<path d={item.icon} fill="currentColor" />
					</svg>
					<span class="sr">{item.label}</span>
				</button>
			</li>
		{/each}
	</ul>

	<button class="item logout" title="Logout" onclick={onlogout}>
		<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
			<path
				d="M10 3H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h5v-2H5V5h5zm9.5 9-4-4v3H9v2h6.5v3z"
				fill="currentColor"
			/>
		</svg>
		<span class="sr">Logout</span>
	</button>
</nav>

<style>
	.rail {
		width: 52px;
		flex: 0 0 52px;
		background: var(--color-surface);
		border-right: 1px solid var(--color-border);
		display: flex;
		flex-direction: column;
		align-items: center;
		padding: var(--space-md) 0 var(--space-sm);
	}
	.logo {
		margin-bottom: var(--space-lg);
	}
	ul {
		list-style: none;
		margin: 0;
		padding: 0;
		display: flex;
		flex-direction: column;
		flex: 1;
		width: 100%;
		align-items: center;
	}
	li {
		padding: 2px 4px;
		width: 100%;
		display: flex;
		justify-content: center;
	}
	.divider {
		height: 1px;
		margin: var(--space-xs) var(--space-sm);
		background: var(--color-border-subtle);
	}
	.item {
		width: 44px;
		height: 40px;
		display: grid;
		place-items: center;
		background: transparent;
		border: 1px solid transparent;
		border-left: 3px solid transparent;
		border-radius: var(--radius-tight);
		color: var(--color-text-secondary);
		cursor: pointer;
		transition:
			background var(--motion-fast) var(--motion-ease),
			color var(--motion-fast) var(--motion-ease),
			border-color var(--motion-fast) var(--motion-ease);
	}
	.item:hover {
		background: var(--color-surface-2);
		color: var(--color-text-primary);
		border-color: var(--color-border-subtle);
	}
	.item.active {
		background: var(--color-surface-active);
		color: var(--color-accent);
		border-left-color: var(--color-accent);
	}
	.logout {
		margin-top: var(--space-sm);
		color: var(--color-error);
	}
	.logout:hover {
		background: var(--color-error-subtle);
		color: var(--color-error);
	}
	.sr {
		position: absolute;
		width: 1px;
		height: 1px;
		overflow: hidden;
		clip: rect(0 0 0 0);
		white-space: nowrap;
	}
</style>
