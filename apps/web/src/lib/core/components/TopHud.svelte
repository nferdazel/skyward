<script lang="ts">
	import type { AppUser } from '$lib/features/auth/domain/user';
	import type { SimulationState } from '$lib/features/simulation/state/simulation-store.svelte';

	/**
	 * Top command bar (42px). Ported from Flutter `TopHud`.
	 * Left: HQ badge, company/CEO, pulsing game clock.
	 * Centre: cash + telemetry. Right: notifications.
	 */
	type Props = {
		user: AppUser;
		sim: SimulationState;
		unreadCount?: number;
		onnotifications?: () => void;
	};

	let { user, sim, unreadCount = 0, onnotifications }: Props = $props();

	const money = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const gameDate = $derived.by(() => {
		const d = new Date(sim.gameTime);
		return Number.isNaN(d.getTime()) ? '—' : d.toISOString().slice(0, 10);
	});
</script>

<header class="hud">
	<div class="left">
		<span class="hq">{user.hqAirportIata || 'HQ'}</span>
		<div class="identity">
			<span class="company">{user.companyName.toUpperCase()}</span>
			<span class="ceo">CEO {user.ceoName}</span>
		</div>
		<span class="sep" aria-hidden="true"></span>
		<span class="clock">
			<span class="pulse" aria-hidden="true"></span>
			<span class="tnum">{gameDate}</span>
		</span>
	</div>

	<div class="center">
		<span class="metric">
			<span class="k">CASH</span>
			<span class="v tnum" class:neg={sim.cashBalance < 0}
				>${money.format(Math.round(sim.cashBalance))}</span
			>
		</span>
		<span class="metric">
			<span class="k">FLIGHTS</span>
			<span class="v tnum">{sim.lastFlightsRun}</span>
		</span>
		<span class="metric">
			<span class="k">STATUS</span>
			<span class="v">{sim.operationalStatus}</span>
		</span>
	</div>

	<div class="right">
		<button class="bell" aria-label="Notifications" onclick={onnotifications}>
			<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
				<path
					d="M12 22a2.5 2.5 0 0 0 2.45-2h-4.9A2.5 2.5 0 0 0 12 22zm7-5v-1l-1.5-1.5V10a5.5 5.5 0 0 0-4-5.3V4a1.5 1.5 0 0 0-3 0v.7A5.5 5.5 0 0 0 6.5 10v4.5L5 16v1z"
					fill="currentColor"
				/>
			</svg>
			{#if unreadCount > 0}<span class="badge">{unreadCount}</span>{/if}
		</button>
	</div>
</header>

<style>
	.hud {
		height: 42px;
		flex: 0 0 42px;
		display: flex;
		align-items: center;
		gap: var(--space-md);
		padding: 0 var(--space-md);
		background: var(--color-surface);
		border-bottom: 1px solid var(--color-border);
	}
	.left {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
		min-width: 0;
	}
	.hq {
		padding: 2px 6px;
		background: var(--color-surface-2);
		border: 1px solid var(--color-border-subtle);
		border-radius: var(--radius-tight);
		color: var(--color-accent);
		font-size: 10px;
		font-weight: 700;
		letter-spacing: 0.08em;
	}
	.identity {
		display: flex;
		flex-direction: column;
		line-height: 1.15;
		min-width: 0;
	}
	.company {
		font-size: 10px;
		font-weight: 600;
		letter-spacing: 0.08em;
		white-space: nowrap;
	}
	.ceo {
		font-size: 10px;
		color: var(--color-text-muted);
		white-space: nowrap;
	}
	.sep {
		width: 1px;
		height: 20px;
		background: var(--color-border-subtle);
	}
	.clock {
		display: flex;
		align-items: center;
		gap: var(--space-xs);
		font-size: 12px;
	}
	.pulse {
		width: 6px;
		height: 6px;
		border-radius: 50%;
		background: var(--color-accent);
		animation: pulse 2s var(--motion-ease) infinite;
	}
	@keyframes pulse {
		0%,
		100% {
			opacity: 1;
		}
		50% {
			opacity: 0.35;
		}
	}
	.center {
		margin-left: auto;
		display: flex;
		align-items: center;
		gap: var(--space-lg);
	}
	.metric {
		display: flex;
		align-items: baseline;
		gap: var(--space-xs);
	}
	.k {
		font-size: 10px;
		color: var(--color-text-muted);
		letter-spacing: 0.08em;
	}
	.v {
		font-size: 12px;
		font-weight: 700;
		color: var(--color-success);
	}
	.v.neg {
		color: var(--color-error);
	}
	.right {
		display: flex;
		align-items: center;
	}
	.bell {
		position: relative;
		display: grid;
		place-items: center;
		width: 32px;
		height: 32px;
		background: transparent;
		border: none;
		border-radius: var(--radius-tight);
		color: var(--color-text-secondary);
		cursor: pointer;
	}
	.bell:hover {
		background: var(--color-surface-2);
		color: var(--color-text-primary);
	}
	.badge {
		position: absolute;
		top: 2px;
		right: 2px;
		min-width: 14px;
		height: 14px;
		padding: 0 3px;
		border-radius: 7px;
		background: var(--color-error);
		color: #fff;
		font-size: 9px;
		font-weight: 700;
		display: grid;
		place-items: center;
	}
	@media (prefers-reduced-motion: reduce) {
		.pulse {
			animation: none;
		}
	}
</style>
