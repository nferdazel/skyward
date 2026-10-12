import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
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

function filterStore(): FleetStore {
	return makeStore({
		catalog: [
			aircraftModelFromMap({
				id: 'm1',
				model_name: 'A320',
				manufacturer: 'Airbus',
				type: 'narrow_body_jet',
				range_km: 5000,
				purchase_price: 900
			}),
			aircraftModelFromMap({
				id: 'm2',
				model_name: 'B737',
				manufacturer: 'Boeing',
				type: 'narrow_body_jet',
				range_km: 5600,
				purchase_price: 500
			}),
			aircraftModelFromMap({
				id: 'm3',
				model_name: 'ATR72',
				manufacturer: 'ATR',
				type: 'regional_turboprop',
				range_km: 1500,
				purchase_price: 200
			})
		]
	});
}

/** Nama kartu katalog, urut sesuai DOM. */
function cardNames(): string[] {
	return Array.from(document.querySelectorAll('.name')).map((el) => el.textContent?.trim() ?? '');
}

describe('AcquireTab catalog filters', () => {
	it('lists the catalog cheapest first', () => {
		render(AcquireTab, { props: { store: filterStore() } });
		expect(cardNames()).toEqual(['ATR ATR72', 'Boeing B737', 'Airbus A320']);
	});

	it('filters by manufacturer', async () => {
		render(AcquireTab, { props: { store: filterStore() } });

		await userEvent.click(screen.getByRole('button', { name: /manufacturer/i }));
		await userEvent.click(screen.getByRole('checkbox', { name: 'AIRBUS' }));
		await userEvent.click(screen.getByRole('button', { name: 'Apply' }));

		expect(cardNames()).toEqual(['Airbus A320']);
		expect(screen.getByText('1 of 3 models')).toBeInTheDocument();
	});

	it('combines category and range with AND, and can clear them again', async () => {
		render(AcquireTab, { props: { store: filterStore() } });

		await userEvent.click(screen.getByRole('button', { name: /category/i }));
		await userEvent.click(screen.getByRole('checkbox', { name: 'REGIONAL TURBOPROP' }));
		await userEvent.click(screen.getByRole('button', { name: 'Apply' }));

		await userEvent.click(screen.getByRole('button', { name: /range/i }));
		await userEvent.click(screen.getByRole('checkbox', { name: 'LONG RANGE (6,000+ KM)' }));
		await userEvent.click(screen.getByRole('button', { name: 'Apply' }));

		expect(screen.getByText('No models match the filters.')).toBeInTheDocument();

		await userEvent.click(screen.getByRole('button', { name: 'Clear filters' }));
		expect(cardNames()).toHaveLength(3);
	});

	it('uses inclusive range brackets at 2,000 km and 6,000 km', async () => {
		const store = makeStore({
			catalog: [
				aircraftModelFromMap({
					id: 'a',
					model_name: 'R1999',
					manufacturer: 'T',
					range_km: 1999,
					purchase_price: 1
				}),
				aircraftModelFromMap({
					id: 'b',
					model_name: 'R2000',
					manufacturer: 'T',
					range_km: 2000,
					purchase_price: 2
				}),
				aircraftModelFromMap({
					id: 'c',
					model_name: 'R6000',
					manufacturer: 'T',
					range_km: 6000,
					purchase_price: 3
				}),
				aircraftModelFromMap({
					id: 'd',
					model_name: 'R6001',
					manufacturer: 'T',
					range_km: 6001,
					purchase_price: 4
				})
			]
		});
		render(AcquireTab, { props: { store } });

		await userEvent.click(screen.getByRole('button', { name: /range/i }));
		await userEvent.click(
			screen.getByRole('checkbox', { name: 'MEDIUM RANGE (2,000 - 6,000 KM)' })
		);
		await userEvent.click(screen.getByRole('button', { name: 'Apply' }));

		expect(cardNames()).toEqual(['T R2000', 'T R6000']);
	});
});
