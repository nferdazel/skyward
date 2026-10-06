import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import AcquireTab from './AcquireTab.svelte';
import type { FleetStore } from '../state/fleet-store.svelte';
import { aircraftModelFromMap } from '../domain/fleet-models';

function makeStore(over: Partial<FleetStore['state']> = {}): FleetStore {
	return {
		state: {
			loading: false,
			aircraft: [],
			catalog: [
				aircraftModelFromMap({ id: 'm1', model_name: 'A320', min_credit_tier: 'Gold' }),
				aircraftModelFromMap({ id: 'm2', model_name: 'C208', min_credit_tier: 'Standard' })
			],
			error: null,
			...over
		},
		purchase: vi.fn(),
		lease: vi.fn(),
		configureSeats: vi.fn(),
		refresh: vi.fn(),
		load: vi.fn()
	} as unknown as FleetStore;
}

describe('AcquireTab tier gating', () => {
	it('locks models above the player credit tier', () => {
		render(AcquireTab, { props: { store: makeStore(), creditTier: 'Silver' } });
		// Gold model is locked; Standard model is acquirable.
		expect(screen.getByText('Requires credit tier Gold')).toBeInTheDocument();
		expect(screen.getByText('Locked')).toBeInTheDocument();
		expect(screen.getByRole('button', { name: 'Acquire' })).toBeInTheDocument();
	});

	it('unlocks everything at Platinum', () => {
		render(AcquireTab, { props: { store: makeStore(), creditTier: 'Platinum' } });
		expect(screen.queryByText('Locked')).toBeNull();
		expect(screen.getAllByRole('button', { name: 'Acquire' })).toHaveLength(2);
	});

	it('offers a Finance mode only when onFinance is provided', async () => {
		const onFinance = vi.fn().mockResolvedValue(undefined);
		const { unmount } = render(AcquireTab, {
			props: { store: makeStore(), creditTier: 'Platinum', onFinance }
		});

		await screen.getAllByRole('button', { name: 'Acquire' })[0].click();
		// The drawer's mode switcher now has a Finance tab.
		expect(screen.getByRole('button', { name: 'Finance' })).toBeInTheDocument();
		unmount();

		render(AcquireTab, { props: { store: makeStore(), creditTier: 'Platinum' } });
		await screen.getAllByRole('button', { name: 'Acquire' })[0].click();
		expect(screen.queryByRole('button', { name: 'Finance' })).toBeNull();
	});
});
