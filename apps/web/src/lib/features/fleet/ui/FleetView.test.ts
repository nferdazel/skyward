import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import FleetView from './FleetView.svelte';
import type { FleetStore } from '../state/fleet-store.svelte';
import { userFleetAircraftFromMap } from '../domain/fleet-models';

function makeStore(over: Partial<FleetStore['state']> = {}): FleetStore {
	const aircraft = userFleetAircraftFromMap({
		id: 'a1',
		nickname: 'Niner',
		tail_number: '9V-AAA',
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
	it('lists aircraft with condition and cabin', () => {
		render(FleetView, { props: { store: makeStore() } });
		// Tail number and condition appear in the table and the inspector drawer.
		expect(screen.getAllByText('9V-AAA').length).toBeGreaterThan(0);
		expect(screen.getAllByText('82%').length).toBeGreaterThan(0);
		expect(screen.getByText(/E 0 B 0 F 0/)).toBeInTheDocument();
	});

	it('shows an empty state when there are no aircraft', () => {
		render(FleetView, { props: { store: makeStore({ aircraft: [] }) } });
		expect(screen.getByText(/No aircraft yet/)).toBeInTheDocument();
	});
});
