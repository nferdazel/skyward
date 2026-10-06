import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import OnboardingOverlay from './OnboardingOverlay.svelte';

describe('OnboardingOverlay', () => {
	it('shows the welcome step and advances through NEXT', async () => {
		render(OnboardingOverlay, { props: { oncomplete: vi.fn() } });
		expect(screen.getByText('Welcome to Skyward')).toBeInTheDocument();

		await screen.getByRole('button', { name: 'NEXT' }).click();
		expect(screen.getByText('Step 1: Acquire Aircraft')).toBeInTheDocument();
	});

	it('navigates to a tab from a step action', async () => {
		const onnavigate = vi.fn();
		render(OnboardingOverlay, { props: { oncomplete: vi.fn(), onnavigate } });

		await screen.getByRole('button', { name: 'NEXT' }).click();
		await screen.getByRole('button', { name: 'Go to Fleet' }).click();

		expect(onnavigate).toHaveBeenCalledWith('fleet');
	});

	it('completes on SKIP', async () => {
		const oncomplete = vi.fn();
		render(OnboardingOverlay, { props: { oncomplete } });

		await screen.getByRole('button', { name: 'SKIP' }).click();

		expect(oncomplete).toHaveBeenCalledOnce();
	});

	it('reaches the final step and starts playing', async () => {
		const oncomplete = vi.fn();
		render(OnboardingOverlay, { props: { oncomplete } });

		for (let i = 0; i < 4; i++) {
			await screen.getByRole('button', { name: 'NEXT' }).click();
		}
		expect(screen.getByText("You're Ready!")).toBeInTheDocument();
		await screen.getByRole('button', { name: 'START PLAYING' }).click();
		expect(oncomplete).toHaveBeenCalledOnce();
	});
});
