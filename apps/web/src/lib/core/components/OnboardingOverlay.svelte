<script lang="ts">
	import TactileButton from '$lib/core/components/TactileButton.svelte';

	/**
	 * First-run onboarding overlay. Ported from Flutter `OnboardingOverlay`:
	 * 5 steps with a dot indicator, back/next, skip, and step actions that jump
	 * to the relevant tab. On completion the caller persists onboarding.
	 */
	type Props = {
		oncomplete: () => void;
		onnavigate?: (tab: string) => void;
	};
	let { oncomplete, onnavigate }: Props = $props();

	type Step = {
		title: string;
		description: string;
		icon: string;
		actionLabel?: string;
		actionTab?: string;
	};

	const steps: Step[] = [
		{
			title: 'Welcome to Skyward',
			description:
				"Build your airline from the ground up. Acquire aircraft, establish routes, and compete against AI rivals to become the world's top airline.",
			icon: 'M2.5 19h19v2h-19zm19.57-9.36c-.21-.8-1.04-1.28-1.84-1.06L14.92 10 8 3.23 6.09 3.74l3.73 6.46-4.35 1.17-1.72-1.34-1.44.39 1.8 3.12 1.16 2.02z'
		},
		{
			title: 'Step 1: Acquire Aircraft',
			description:
				'Open the Fleet tab and acquire your first aircraft. You can buy or lease: leasing requires less upfront capital.',
			icon: 'M21 16v-2l-8-5V3.5a1.5 1.5 0 0 0-3 0V9l-8 5v2l8-2.5V19l-2 1.5V22l3.5-1 3.5 1v-1.5L13 19v-5.5z',
			actionLabel: 'Go to Fleet',
			actionTab: 'fleet'
		},
		{
			title: 'Step 2: Create a Route',
			description:
				'Open the Routes tab and use the Blueprint Planner to create your first flight connection between two airports.',
			icon: 'M12 2a7 7 0 0 0-7 7c0 5 7 13 7 13s7-8 7-13a7 7 0 0 0-7-7zm0 9.5A2.5 2.5 0 1 1 12 6a2.5 2.5 0 0 1 0 5.5z',
			actionLabel: 'Go to Routes',
			actionTab: 'routes'
		},
		{
			title: 'Step 3: Assign & Fly',
			description:
				'Assign your aircraft to the route. Once assigned, the simulation will automatically process flights and generate revenue.',
			icon: 'M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm-2 14.5v-9l7 4.5z'
		},
		{
			title: "You're Ready!",
			description:
				'Monitor your finances, expand your fleet, and climb the leaderboard. The simulation ticks every minute — your airline is always running.',
			icon: 'M5 3h14v2H5zm7 3a6 6 0 1 0 0 12 6 6 0 0 0 0-12zm0 2.5 1.9 3.9 4.1.6-3 2.9.7 4.1-3.7-2-3.7 2 .7-4.1-3-2.9 4.1-.6z',
			actionLabel: 'Start Playing'
		}
	];

	let currentStep = $state(0);
	let dismissed = $state(false);

	const isLast = $derived(currentStep === steps.length - 1);
	const step = $derived(steps[currentStep]);

	function next() {
		if (isLast) complete();
		else currentStep++;
	}
	function back() {
		if (currentStep > 0) currentStep--;
	}
	function complete() {
		if (dismissed) return;
		dismissed = true;
		oncomplete();
	}
	function doAction() {
		if (step.actionTab && onnavigate) onnavigate(step.actionTab);
		next();
	}
</script>

<div class="overlay" role="dialog" aria-modal="true" aria-label="Onboarding">
	<div class="skip">
		<TactileButton text="SKIP" type="secondary" height="40px" onclick={complete} />
	</div>

	<div class="card">
		<div class="dots" aria-hidden="true">
			{#each steps as stepItem, i (i)}
				<span class="dot" class:active={i === currentStep} title={stepItem.title}></span>
			{/each}
		</div>

		<div class="step">
			<svg viewBox="0 0 24 24" width="48" height="48" aria-hidden="true">
				<path d={step.icon} fill="var(--color-accent)" />
			</svg>
			<h2>{step.title}</h2>
			<p>{step.description}</p>
		</div>

		<div class="actions">
			{#if currentStep > 0}
				<TactileButton text="BACK" type="secondary" height="40px" onclick={back} />
			{:else}
				<span class="spacer"></span>
			{/if}

			{#if step.actionLabel && step.actionTab}
				<TactileButton text={step.actionLabel} type="primary" height="40px" onclick={doAction} />
			{/if}
			<TactileButton
				text={isLast ? 'START PLAYING' : 'NEXT'}
				type="primary"
				height="40px"
				onclick={next}
			/>
		</div>
	</div>
</div>

<style>
	.overlay {
		position: fixed;
		inset: 0;
		z-index: 300;
		background: rgb(0 0 0 / 0.85);
		display: grid;
		place-items: center;
		padding: var(--space-xxl);
	}
	.skip {
		position: absolute;
		top: var(--space-lg);
		right: var(--space-lg);
	}
	.card {
		width: 100%;
		max-width: 480px;
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-round);
		padding: var(--space-xxxl);
		display: flex;
		flex-direction: column;
		gap: var(--space-xxxl);
	}
	.dots {
		display: flex;
		justify-content: center;
		gap: var(--space-xs);
	}
	.dot {
		width: 8px;
		height: 8px;
		border-radius: var(--radius-default);
		background: var(--color-border);
		transition: width var(--motion-base) var(--motion-ease);
	}
	.dot.active {
		width: var(--space-xxl);
		background: var(--color-accent);
	}
	.step {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: var(--space-md);
		text-align: center;
	}
	h2 {
		margin: 0;
		font-size: 20px;
	}
	p {
		margin: 0;
		color: var(--color-text-secondary);
		font-size: 14px;
		line-height: 1.5;
	}
	.actions {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: var(--space-sm);
	}
	.spacer {
		width: 80px;
	}
	@media (prefers-reduced-motion: no-preference) {
		.card {
			animation: pop var(--motion-slow) var(--motion-ease-out);
		}
	}
	@keyframes pop {
		from {
			opacity: 0;
			transform: translateY(12px) scale(0.98);
		}
		to {
			opacity: 1;
			transform: none;
		}
	}
</style>
