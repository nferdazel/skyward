<script lang="ts">
	import { cabinSlotCost } from '$lib/core/theme/tokens';

	type Props = {
		capacity: number;
		economy: number;
		business: number;
		firstClass: number;
		manufacturer?: string;
		modelName?: string;
		tailNumber?: string;
	};

	let { capacity, economy, business, firstClass, manufacturer, modelName, tailNumber }: Props =
		$props();

	// Calculate slot arithmetic
	const ecoSlots = $derived(economy * cabinSlotCost.economy);
	const busSlots = $derived(business * cabinSlotCost.business);
	const firstSlots = $derived(firstClass * cabinSlotCost.firstClass);
	const totalSlots = $derived(ecoSlots + busSlots + firstSlots);
	const totalPassengers = $derived(economy + business + firstClass);
	const remainingSlots = $derived(capacity - totalSlots);
	const isValid = $derived(totalSlots <= capacity);

	const ecoPct = $derived(capacity > 0 ? (ecoSlots / capacity) * 100 : 0);
	const busPct = $derived(capacity > 0 ? (busSlots / capacity) * 100 : 0);
	const firstPct = $derived(capacity > 0 ? (firstSlots / capacity) * 100 : 0);
</script>

<div class="cabin-visualizer" role="region" aria-label="Aircraft Cabin Seating Visualizer">
	<div class="deck-header">
		<div class="aircraft-identity">
			{#if tailNumber}
				<span class="tail mono">{tailNumber}</span>
			{/if}
			{#if modelName}
				<span class="model-name"
					>{manufacturer ? `${manufacturer.toUpperCase()} ` : ''}{modelName}</span
				>
			{/if}
		</div>
		<div class="allocation-badge mono tnum" class:invalid={!isValid}>
			<span class="beacon" aria-hidden="true"></span>
			<span>{totalSlots} / {capacity} SLOTS</span>
			{#if !isValid}
				<span class="overage">({totalSlots - capacity} OVER)</span>
			{/if}
		</div>
	</div>

	<!-- Fuselage cross-section & deck representation -->
	<div class="fuselage-deck">
		<!-- Cockpit nose cone -->
		<div class="fuselage-nose">
			<div class="windshield" title="Flight Deck / Avionics Cockpit"></div>
		</div>

		<!-- Main Cabin Deck Container -->
		<div class="cabin-body">
			<!-- First Class Section -->
			{#if firstClass > 0}
				<div
					class="deck-section first-class"
					title="First Class: {firstClass} seats ({firstSlots} slots)"
				>
					<div class="section-label micro-label">FIRST CLASS ({firstClass})</div>
					<div class="seat-grid layout-1-1">
						{#each Array(Math.min(firstClass, 8)) as _, i (i)}
							<div class="seat-pod first" aria-hidden="true">
								<span class="seat-cushion"></span>
							</div>
						{/each}
						{#if firstClass > 8}
							<div class="overflow-tag mono">+{firstClass - 8}</div>
						{/if}
					</div>
				</div>
			{/if}

			<!-- Business Class Section -->
			{#if business > 0}
				<div
					class="deck-section business-class"
					title="Business Class: {business} seats ({busSlots} slots)"
				>
					<div class="section-label micro-label">BUSINESS ({business})</div>
					<div class="seat-grid layout-2-2">
						{#each Array(Math.min(business, 12)) as _, i (i)}
							<div class="seat-pod business" aria-hidden="true">
								<span class="seat-cushion"></span>
							</div>
						{/each}
						{#if business > 12}
							<div class="overflow-tag mono">+{business - 12}</div>
						{/if}
					</div>
				</div>
			{/if}

			<!-- Economy Class Section -->
			<div
				class="deck-section economy-class"
				title="Economy Class: {economy} seats ({ecoSlots} slots)"
			>
				<div class="section-label micro-label">ECONOMY ({economy})</div>
				<div class="seat-grid layout-3-3">
					{#each Array(Math.min(economy, 18)) as _, i (i)}
						<div class="seat-pod economy" aria-hidden="true">
							<span class="seat-cushion"></span>
						</div>
					{/each}
					{#if economy > 18}
						<div class="overflow-tag mono">+{economy - 18}</div>
					{/if}
				</div>
			</div>
		</div>

		<!-- Fuselage Tail cone -->
		<div class="fuselage-tail" aria-hidden="true">
			<div class="tail-fin"></div>
		</div>
	</div>

	<!-- Proportional slot bar -->
	<div class="slot-meter" role="progressbar" aria-valuenow={totalSlots} aria-valuemax={capacity}>
		<div
			class="slot-bar first-bar"
			style="width: {firstPct}%;"
			title="First Class: {firstSlots} slots"
		></div>
		<div
			class="slot-bar bus-bar"
			style="width: {busPct}%;"
			title="Business: {busSlots} slots"
		></div>
		<div class="slot-bar eco-bar" style="width: {ecoPct}%;" title="Economy: {ecoSlots} slots"></div>
	</div>

	<!-- Metrics summary line -->
	<div class="cabin-summary mono tnum">
		<div class="metric-item">
			<span class="dot first-dot"></span>
			<span class="label">FIRST:</span>
			<span class="val">{firstClass} <span class="dim">({firstSlots}s)</span></span>
		</div>
		<div class="metric-item">
			<span class="dot bus-dot"></span>
			<span class="label">BUS:</span>
			<span class="val">{business} <span class="dim">({busSlots}s)</span></span>
		</div>
		<div class="metric-item">
			<span class="dot eco-dot"></span>
			<span class="label">ECO:</span>
			<span class="val">{economy} <span class="dim">({ecoSlots}s)</span></span>
		</div>
		<div class="metric-item total-item">
			<span class="label">PAX:</span>
			<span class="val highlight">{totalPassengers}</span>
		</div>
		<div class="metric-item remaining-item">
			<span class="label">FREE:</span>
			<span class="val" class:alert={!isValid}>{remainingSlots}</span>
		</div>
	</div>
</div>

<style>
	.cabin-visualizer {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		padding: var(--space-md);
	}

	.deck-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding-bottom: var(--space-xs);
		border-bottom: 1px solid var(--color-border-subtle);
	}

	.aircraft-identity {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
	}

	.tail {
		font-size: 11px;
		font-weight: 700;
		padding: 2px 6px;
		background: var(--color-surface-2);
		border: 1px solid var(--color-border-highlight);
		border-radius: var(--radius-tight);
		color: var(--color-accent);
	}

	.model-name {
		font-size: 12px;
		font-weight: 600;
		color: var(--color-text-primary);
		letter-spacing: 0.04em;
	}

	.allocation-badge {
		display: flex;
		align-items: center;
		gap: 6px;
		font-size: 11px;
		font-weight: 700;
		color: var(--color-success);
	}

	.allocation-badge.invalid {
		color: var(--color-error);
	}

	.beacon {
		width: 6px;
		height: 6px;
		border-radius: 50%;
		background-color: currentColor;
	}

	.overage {
		color: var(--color-error);
	}

	/* Fuselage representation */
	.fuselage-deck {
		position: relative;
		display: flex;
		align-items: stretch;
		background: var(--color-bg);
		border: 1px solid var(--color-border-subtle);
		border-radius: 40px 12px 12px 40px;
		padding: var(--space-xs);
		min-height: 90px;
		overflow-x: auto;
	}

	.fuselage-nose {
		flex: 0 0 36px;
		display: flex;
		align-items: center;
		justify-content: center;
		border-right: 1px dashed var(--color-border-subtle);
	}

	.windshield {
		width: 14px;
		height: 48px;
		background: var(--color-surface-3);
		border: 1px solid var(--color-accent);
		border-radius: 12px 2px 2px 12px;
		box-shadow: inset 0 0 6px var(--color-accent-subtle);
	}

	.cabin-body {
		flex: 1;
		display: flex;
		align-items: stretch;
		gap: var(--space-sm);
		padding: 0 var(--space-sm);
	}

	.deck-section {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		padding: var(--space-xs);
		border-radius: var(--radius-tight);
		background: var(--color-surface);
		border: 1px solid var(--color-border-subtle);
	}

	.first-class {
		border-top: 2px solid var(--color-gold);
	}

	.business-class {
		border-top: 2px solid var(--color-accent);
	}

	.economy-class {
		flex: 1;
		border-top: 2px solid var(--color-teal);
	}

	.section-label {
		font-size: 9px;
		color: var(--color-text-secondary);
		white-space: nowrap;
	}

	.seat-grid {
		display: flex;
		flex-wrap: wrap;
		gap: 3px;
		align-items: center;
	}

	.seat-pod {
		border-radius: 2px;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.seat-pod.first {
		width: 16px;
		height: 18px;
		background: rgba(255, 215, 0, 0.15);
		border: 1px solid var(--color-gold);
	}

	.seat-pod.business {
		width: 13px;
		height: 15px;
		background: var(--color-accent-subtle);
		border: 1px solid var(--color-accent);
	}

	.seat-pod.economy {
		width: 10px;
		height: 12px;
		background: var(--color-teal-subtle);
		border: 1px solid var(--color-teal);
	}

	.overflow-tag {
		font-size: 10px;
		color: var(--color-text-muted);
		padding: 0 4px;
	}

	.fuselage-tail {
		flex: 0 0 24px;
		display: flex;
		align-items: center;
		justify-content: center;
		border-left: 1px dashed var(--color-border-subtle);
	}

	.tail-fin {
		width: 6px;
		height: 40px;
		background: var(--color-surface-2);
		border-radius: 1px 4px 4px 1px;
	}

	/* Slot meter */
	.slot-meter {
		display: flex;
		height: 8px;
		width: 100%;
		background: var(--color-surface-2);
		border-radius: var(--radius-tight);
		overflow: hidden;
		border: 1px solid var(--color-border-subtle);
	}

	.slot-bar {
		height: 100%;
		transition: width var(--motion-base) var(--motion-ease-out);
	}

	.first-bar {
		background: var(--color-gold);
	}

	.bus-bar {
		background: var(--color-accent);
	}

	.eco-bar {
		background: var(--color-teal);
	}

	/* Cabin summary row */
	.cabin-summary {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		justify-content: space-between;
		font-size: 11px;
		gap: var(--space-xs);
		padding-top: var(--space-xs);
		border-top: 1px solid var(--color-border-subtle);
	}

	.metric-item {
		display: flex;
		align-items: center;
		gap: 4px;
	}

	.dot {
		width: 6px;
		height: 6px;
		border-radius: 50%;
	}

	.first-dot {
		background: var(--color-gold);
	}

	.bus-dot {
		background: var(--color-accent);
	}

	.eco-dot {
		background: var(--color-teal);
	}

	.label {
		color: var(--color-text-muted);
	}

	.val {
		color: var(--color-text-primary);
		font-weight: 600;
	}

	.val.highlight {
		color: var(--color-accent);
	}

	.val.alert {
		color: var(--color-error);
	}

	.dim {
		color: var(--color-text-muted);
		font-weight: 400;
	}
</style>
