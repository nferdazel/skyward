import { describe, expect, it, vi } from 'vitest';
import { FleetStore } from './fleet-store.svelte';
import type { FleetGateway } from '../data/fleet-gateway';
import {
	canOperateDistance,
	effectivePassengerCapacity,
	isMaintenanceGrounded,
	userFleetAircraftFromMap,
	type UserFleetAircraft
} from '../domain/fleet-models';

function aircraft(over: Partial<UserFleetAircraft> = {}): UserFleetAircraft {
	return {
		...userFleetAircraftFromMap({
			id: 'a1',
			acquisition_type: 'purchase',
			condition: 80,
			status: 'active',
			aircraft_models: { id: 'm1', model_name: 'A320', range_km: 5000, capacity: 180 }
		}),
		...over
	};
}

function makeGateway(over: Partial<FleetGateway> = {}): FleetGateway {
	return {
		loadFleet: vi.fn().mockResolvedValue([]),
		loadCatalog: vi.fn().mockResolvedValue([]),
		purchaseAircraft: vi.fn().mockResolvedValue(undefined),
		leaseAircraft: vi.fn().mockResolvedValue(undefined),
		repairAircraft: vi.fn().mockResolvedValue(undefined),
		sellAircraft: vi.fn().mockResolvedValue(undefined),
		terminateLease: vi.fn().mockResolvedValue(undefined),
		configureSeats: vi.fn().mockResolvedValue(undefined),
		fetchLatestAircraftForModel: vi.fn().mockResolvedValue(null),
		fetchSingleAircraft: vi.fn().mockResolvedValue(null),
		...over
	} as unknown as FleetGateway;
}

describe('fleet domain helpers', () => {
	it('computes effective capacity from configured seats, else model', () => {
		expect(effectivePassengerCapacity(aircraft())).toBe(180);
		expect(effectivePassengerCapacity(aircraft({ economySeats: 150 }))).toBe(150);
	});

	it('grounds when condition is below the effective threshold', () => {
		expect(isMaintenanceGrounded(aircraft({ condition: 20 }), 40)).toBe(true);
		expect(isMaintenanceGrounded(aircraft({ condition: 80 }), 40)).toBe(false);
		expect(isMaintenanceGrounded(aircraft({ status: 'grounded' }), 0)).toBe(true);
	});

	it('checks range against the model', () => {
		expect(canOperateDistance(aircraft(), 4000)).toBe(true);
		expect(canOperateDistance(aircraft(), 6000)).toBe(false);
	});
});

describe('FleetStore', () => {
	it('load fills aircraft and catalog', async () => {
		const gateway = makeGateway({
			loadFleet: vi.fn().mockResolvedValue([aircraft()]),
			loadCatalog: vi.fn().mockResolvedValue([{ id: 'm1', modelName: 'A320' }])
		});
		const store = new FleetStore(gateway);

		await store.load();

		expect(store.state.aircraft).toHaveLength(1);
		expect(store.state.catalog).toHaveLength(1);
		expect(store.state.loading).toBe(false);
	});

	it('purchase refetches the fleet afterwards', async () => {
		const loadFleet = vi.fn().mockResolvedValue([]);
		const purchaseAircraft = vi.fn().mockResolvedValue(undefined);
		const store = new FleetStore(makeGateway({ loadFleet, purchaseAircraft }));

		const ok = await store.purchase({
			modelId: 'm1',
			nickname: 'Niner',
			economySeats: 150,
			businessSeats: 12,
			firstClassSeats: 0
		});

		expect(ok).toBe(true);
		expect(purchaseAircraft).toHaveBeenCalledOnce();
		expect(loadFleet).toHaveBeenCalledOnce(); // refetch setelah mutasi
	});

	it('sets an error and returns false when a mutation fails', async () => {
		const store = new FleetStore(
			makeGateway({ sellAircraft: vi.fn().mockRejectedValue(new Error('cannot sell')) })
		);

		const ok = await store.sell('a1');

		expect(ok).toBe(false);
		expect(store.state.error).toBe('cannot sell');
	});
});
