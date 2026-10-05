import { describe, expect, it, vi } from 'vitest';
import { RoutesStore } from './routes-store.svelte';
import type { RoutesGateway } from '../data/routes-gateway';
import { calculateDistance, nearestWithin, type Airport } from '../domain/airport';
import { userRouteFromMap, weeklyASK, flightDurationHours } from '../domain/route-models';
import {
	planAssessmentFromJson,
	routeAssessResultFromJson,
	bestAssessment
} from '../domain/route-assessment';

const SIN: Airport = {
	iata: 'SIN',
	name: 'Changi',
	city: 'Singapore',
	country: 'SG',
	latitude: 1.36,
	longitude: 103.99,
	demandIndex: 90
};
const KUL: Airport = {
	iata: 'KUL',
	name: 'KLIA',
	city: 'Kuala Lumpur',
	country: 'MY',
	latitude: 2.74,
	longitude: 101.7,
	demandIndex: 70
};

function makeGateway(over: Partial<RoutesGateway> = {}): RoutesGateway {
	return {
		loadRoutes: vi.fn().mockResolvedValue([]),
		loadAirports: vi.fn().mockResolvedValue([]),
		loadAvailableFleet: vi.fn().mockResolvedValue([]),
		loadRouteAssessments: vi.fn().mockResolvedValue({}),
		loadGroundingThreshold: vi.fn().mockResolvedValue(40),
		createRoute: vi.fn().mockResolvedValue(undefined),
		assignAircraft: vi.fn().mockResolvedValue(undefined),
		updateRoute: vi.fn().mockResolvedValue(undefined),
		deleteRoute: vi.fn().mockResolvedValue(undefined),
		assessRoute: vi.fn().mockResolvedValue(null),
		...over
	} as unknown as RoutesGateway;
}

describe('airport geometry', () => {
	it('computes haversine distance within tolerance', () => {
		const d = calculateDistance(SIN, KUL);
		expect(d).toBeGreaterThan(280);
		expect(d).toBeLessThan(340);
	});

	it('finds the nearest airport within the radius, skipping self', () => {
		expect(nearestWithin(SIN, [SIN, KUL], 1500)?.iata).toBe('KUL');
		expect(nearestWithin(SIN, [SIN], 1500)).toBeNull();
	});
});

describe('route geometry helpers', () => {
	it('computes ASK and duration from an assigned aircraft', () => {
		const route = userRouteFromMap({
			id: 'r1',
			origin_iata: 'SIN',
			destination_iata: 'KUL',
			distance_km: 300,
			flights_per_week: 7,
			tail_number: '9V-AAA',
			assigned_capacity: 180,
			assigned_range_km: 5000,
			assigned_speed_kmh: 800,
			model_name: 'A320'
		});
		// ASK = 180 * 300 * 7
		expect(weeklyASK(route)).toBe(180 * 300 * 7);
		// durasi = 300/800 + 0.75 = 1.125
		expect(flightDurationHours(route)).toBeCloseTo(1.125);
	});
});

describe('route assessment parsing', () => {
	it('reads snake_case fields and picks the best aircraft by weekly contribution', () => {
		const result = routeAssessResultFromJson({
			route_id: 'r1',
			origin: 'SIN',
			destination: 'KUL',
			distance_km: 300,
			has_compatible_aircraft: true,
			aircraft: [
				{
					aircraft_id: 'a1',
					weekly_contribution: 1000,
					wear: {},
					viability: {},
					multipliers: {},
					inputs_used: {}
				},
				{
					aircraft_id: 'a2',
					weekly_contribution: 2500,
					wear: {},
					viability: {},
					multipliers: {},
					inputs_used: {}
				}
			]
		});
		expect(result.routeId).toBe('r1');
		expect(bestAssessment(result)?.aircraftId).toBe('a2');
	});

	it('treats an unknown viability band conservatively', () => {
		const a = planAssessmentFromJson({ viability: { band: 'experimental', reasons: ['x'] } });
		expect(a.viability.band).toBe('experimental');
	});
});

describe('RoutesStore', () => {
	it('load fills routes, airports, assessments and threshold', async () => {
		const gateway = makeGateway({
			loadRoutes: vi.fn().mockResolvedValue([userRouteFromMap({ id: 'r1' })]),
			loadAirports: vi.fn().mockResolvedValue([SIN]),
			loadRouteAssessments: vi.fn().mockResolvedValue({ r1: { aircraftId: 'a1' } }),
			loadGroundingThreshold: vi.fn().mockResolvedValue(55)
		});
		const store = new RoutesStore(gateway);

		await store.load();

		expect(store.state.routes).toHaveLength(1);
		expect(store.state.airports).toHaveLength(1);
		expect(store.state.assessments.r1).toBeDefined();
		expect(store.state.groundingThreshold).toBe(55);
	});

	it('create refetches routes and assessments', async () => {
		const loadRoutes = vi.fn().mockResolvedValue([]);
		const loadRouteAssessments = vi.fn().mockResolvedValue({});
		const createRoute = vi.fn().mockResolvedValue(undefined);
		const store = new RoutesStore(makeGateway({ loadRoutes, loadRouteAssessments, createRoute }));

		const ok = await store.create({
			originIata: 'SIN',
			destinationIata: 'KUL',
			distanceKm: 300,
			ticketPrice: 120,
			flightsPerWeek: 7
		});

		expect(ok).toBe(true);
		expect(createRoute).toHaveBeenCalledOnce();
		expect(loadRoutes).toHaveBeenCalledOnce();
	});

	it('assign with null sends a release (empty aircraft id)', async () => {
		const assignAircraft = vi.fn().mockResolvedValue(undefined);
		const store = new RoutesStore(makeGateway({ assignAircraft }));

		await store.assign('r1', null);

		expect(assignAircraft).toHaveBeenCalledWith('r1', null);
	});
});
