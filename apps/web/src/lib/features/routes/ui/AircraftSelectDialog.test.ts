import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import AircraftSelectDialog from './AircraftSelectDialog.svelte';
import { userRouteFromMap } from '../domain/route-models';
import { userFleetAircraftFromMap } from '$lib/features/fleet/domain/fleet-models';
import type { RoutesStore } from '../state/routes-store.svelte';

describe('AircraftSelectDialog', () => {
	const route = userRouteFromMap({
		id: 'r1',
		origin_iata: 'CGK',
		destination_iata: 'DPS',
		distance_km: 980,
		ticket_price: 150,
		flights_per_week: 14
	});

	const aircraft = userFleetAircraftFromMap({
		id: 'a1',
		tail_number: 'PK-GIA',
		condition: 90,
		status: 'idle',
		aircraft_models: {
			id: 'm1',
			model_name: 'B737-800',
			manufacturer: 'Boeing',
			range_km: 5400,
			capacity: 180
		}
	});

	const store = {
		state: {
			availableFleet: [aircraft]
		},
		assign: vi.fn().mockResolvedValue(true)
	} as unknown as RoutesStore;

	it('renders available idle aircraft with model and select action', () => {
		render(AircraftSelectDialog, {
			props: {
				store,
				route,
				autoGroundingThreshold: 40,
				onclose: vi.fn()
			}
		});

		expect(screen.getByText(/Fleet Assignment: CGK → DPS/i)).toBeInTheDocument();
		expect(screen.getByText('PK-GIA')).toBeInTheDocument();
		expect(screen.getByText('B737-800')).toBeInTheDocument();
		expect(screen.getByRole('button', { name: 'Select' })).toBeInTheDocument();
	});
});
