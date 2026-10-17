import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import RouteEditModal from './RouteEditModal.svelte';
import { userRouteFromMap } from '../domain/route-models';
import type { RoutesStore } from '../state/routes-store.svelte';

describe('RouteEditModal', () => {
	const route = userRouteFromMap({
		id: 'r1',
		origin_iata: 'CGK',
		destination_iata: 'DPS',
		distance_km: 980,
		ticket_price: 150,
		flights_per_week: 14
	});

	const store = {
		update: vi.fn().mockResolvedValue(true),
		assess: vi.fn().mockResolvedValue(null)
	} as unknown as RoutesStore;

	it('renders dialog title and inputs with initial route values', () => {
		render(RouteEditModal, {
			props: {
				store,
				route,
				baseFare: { base: 50, perKm: 0.1 },
				onclose: vi.fn()
			}
		});

		expect(screen.getByText(/Edit Route: CGK → DPS/i)).toBeInTheDocument();
		expect(screen.getByLabelText(/Ticket Price/)).toHaveValue(150);
		expect(screen.getByLabelText(/Flights Per Week/)).toHaveValue(14);
		expect(screen.getByRole('button', { name: 'Save Changes' })).toBeInTheDocument();
	});
});
