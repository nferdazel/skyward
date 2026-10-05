import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import FleetView from './FleetView.svelte';
import type { FleetStore } from '../state/fleet-store.svelte';
import { userFleetAircraftFromMap } from '../domain/fleet-models';

function makeStore(over: Partial<FleetStore['state']> = {}): FleetStore {
	const aircraft = userFleetAircraftFromMap({
		id: 'a1',
		nickname: 'Niner',
		acquisition_type: 'purchase',
		condition: 82,
		status: 'active',
		can_be_sold: true,
		aircraft_models: { id: 'm1', model_name: 'A320', range_km: 5000, capacity: 180 }
	});
	return {
		state: { loading: false, aircraft: [aircraft], catalog: [], error: null, ...over },
		purchase: vi.fn(),
		lease: vi.fn(),
		repair: vi.fn(),
		sell: vi.fn(),
		configureSeats: vi.fn(),
		refresh: vi.fn(),
		load: vi.fn()
	} as unknown as FleetStore;
}

describe('FleetView', () => {
	it('lists aircraft with condition and actions', () => {
		render(FleetView, { props: { store: makeStore() } });
		expect(screen.getByText('Niner')).toBeInTheDocument();
		expect(screen.getByText('82%')).toBeInTheDocument();
		expect(screen.getByRole('button', { name: 'Perbaiki' })).toBeInTheDocument();
	});

	it('shows an empty state when there are no aircraft', () => {
		render(FleetView, { props: { store: makeStore({ aircraft: [] }) } });
		expect(screen.getByText('Belum ada pesawat')).toBeInTheDocument();
	});
});
