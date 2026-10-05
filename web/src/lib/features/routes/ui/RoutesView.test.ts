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
			assessments: {
				r1: {
					aircraftId: 'a1',
					aircraftModel: 'A320',
					acquisitionType: 'purchase',
					flightsPerWeekRequested: 7,
					allocatedFlightsPerWeek: 7,
					maxWeeklyFlights: 7,
					flightDurationHours: 1,
					expectedPassengersPerFlight: 100,
					seatCapacity: 180,
					loadFactorPercent: 60,
					directOperatingCostPerFlight: 1000,
					revenuePerFlight: 1500,
					contributionPerFlight: 500,
					weeklyContribution: 3500,
					weeklyRevenue: 10500,
					weeklyCargoRevenue: 0,
					weeklyFuelCost: 0,
					weeklyCrewCost: 0,
					weeklyMaintenanceCost: 0,
					weeklyLeaseCost: 0,
					wear: {
						perFlightCycle: 0,
						grossPerWeek: 0,
						selfHealPerWeek: 0,
						netPerWeek: 0,
						conditionAfterOneWeek: 100
					},
					viability: { band: 'strong', reasons: [] },
					multipliers: { fuel: 1, maintenance: 1, demand: 1, capacity: 1 },
					inputsUsed: { ticketPrice: 120, flightsPerWeek: 7 }
				}
			},
			groundingThreshold: 40,
			error: null,
			...over
		},
		create: vi.fn(),
		assign: vi.fn(),
		update: vi.fn(),
		remove: vi.fn(),
		load: vi.fn(),
		refresh: vi.fn()
	} as unknown as RoutesStore;
}

describe('RoutesView', () => {
	it('lists routes with distance, fare and weekly contribution', () => {
		render(RoutesView, { props: { store: makeStore() } });
		expect(screen.getByText('SIN→KUL')).toBeInTheDocument();
		expect(screen.getByText('300 km')).toBeInTheDocument();
		expect(screen.getByText('$3,500')).toBeInTheDocument();
		expect(screen.getByText('STRONG')).toBeInTheDocument();
	});

	it('shows an empty state when there are no routes', () => {
		render(RoutesView, { props: { store: makeStore({ routes: [] }) } });
		expect(screen.getByText('Belum ada rute')).toBeInTheDocument();
	});
});
