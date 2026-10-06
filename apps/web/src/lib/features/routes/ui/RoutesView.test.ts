import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import RoutesView from './RoutesView.svelte';
import type { RoutesStore } from '../state/routes-store.svelte';
import { userRouteFromMap } from '../domain/route-models';

function makeStore(over: Partial<RoutesStore['state']> = {}): RoutesStore {
	return {
		state: {
			loading: false,
			routes: [
				userRouteFromMap({
					id: 'r1',
					origin_iata: 'SIN',
					destination_iata: 'KUL',
					distance_km: 300,
					ticket_price: 120,
					flights_per_week: 7
				})
			],
			airports: [],
			availableFleet: [],
			assessments: {},
			groundingThreshold: 40,
			error: null,
			...over
		},
		create: vi.fn(),
		assign: vi.fn(),
		update: vi.fn(),
		remove: vi.fn(),
		assess: vi.fn().mockResolvedValue(null),
		load: vi.fn(),
		refresh: vi.fn()
	} as unknown as RoutesStore;
}

describe('RoutesView', () => {
	it('renders the route list panel with legs and meta', () => {
		render(RoutesView, { props: { store: makeStore() } });
		expect(screen.getByText('SIN')).toBeInTheDocument();
		expect(screen.getByText('KUL')).toBeInTheDocument();
		expect(screen.getByText('300 KM · 7X/WK')).toBeInTheDocument();
		expect(screen.getByText('$120')).toBeInTheDocument();
	});

	it('shows the blueprint planner heading', () => {
		render(RoutesView, { props: { store: makeStore({ routes: [] }) } });
		expect(screen.getByText('Blueprint planner')).toBeInTheDocument();
	});

	it('shows an empty-state hint when there are no routes', () => {
		render(RoutesView, { props: { store: makeStore({ routes: [] }) } });
		expect(screen.getByText('No routes yet')).toBeInTheDocument();
	});
});
