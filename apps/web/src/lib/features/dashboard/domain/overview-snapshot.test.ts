import { describe, expect, it } from 'vitest';
import {
	buildOverviewSnapshot,
	runwayIndicator,
	financeTotals,
	type OverviewInputs
} from './overview-snapshot';
import type { AppUser } from '$lib/features/auth/domain/user';
import type { SimulationState } from '$lib/features/simulation/state/simulation-store.svelte';
import { userFleetAircraftFromMap } from '$lib/features/fleet/domain/fleet-models';
import { userRouteFromMap } from '$lib/features/routes/domain/route-models';
import { bankTransactionFromMap } from '$lib/features/bank/domain/bank-models';

function user(over: Partial<AppUser> = {}): AppUser {
	return {
		id: 'u1',
		username: 'fredi',
		companyName: 'Sky',
		ceoName: 'Fredi',
		netWorth: 0,
		gameCurrentTime: '2030-01-01T00:00:00Z',
		autoGroundingThreshold: 40,
		hqAirportIata: 'SIN',
		operationalStatus: 'Active',
		consecutiveNegativeDays: 0,
		recoveryStreakDays: 0,
		onboardingCompleted: true,
		actorType: 'REAL',
		...over
	};
}

function sim(over: Partial<SimulationState> = {}): SimulationState {
	return {
		gameTime: '2030-01-01T00:00:00Z',
		cashBalance: 10_000_000,
		fuelPricePerLiter: 0.85,
		gameSpeedMultiplier: 60,
		isSyncing: false,
		lastFlightsRun: 0,
		lastElapsedDays: 0,
		lastRevenue: 0,
		lastExpense: 0,
		operationalStatus: 'Active',
		consecutiveNegativeDays: 0,
		recoveryStreakDays: 0,
		bankruptcyCashThreshold: -5_000_000,
		bankruptcyNegativeDaysThreshold: 30,
		ticketBaseFare: 50,
		ticketPerKmRate: 0.12,
		lastUnlockedAchievements: [],
		errorMessage: null,
		...over
	};
}

function baseInputs(over: Partial<OverviewInputs> = {}): OverviewInputs {
	return {
		user: user(),
		sim: sim(),
		fleet: [],
		routes: [],
		assessments: {},
		finance: null,
		hasExpenseHistory: false,
		totalExpense: 0,
		totalRevenue: 0,
		totalLease: 0,
		totalOperations: 0,
		rankings: [],
		netWorthTrend: [],
		profitTrend: [],
		...over
	};
}

describe('runwayIndicator', () => {
	it('maps null to Unknown/neutral', () => {
		expect(runwayIndicator(null)).toEqual({ label: 'Unknown', color: '#758489' });
	});
	it('uses danger below 14d, warning below 45d, success above', () => {
		expect(runwayIndicator(10).label).toBe('10.0d');
		expect(runwayIndicator(10).color).toBe('#E05555');
		expect(runwayIndicator(30).color).toBe('#E6A817');
		expect(runwayIndicator(90).color).toBe('#34D07B');
	});
});

describe('buildOverviewSnapshot', () => {
	it('counts ready/grounded/idle', () => {
		const fleet = [
			userFleetAircraftFromMap({
				id: 'a1',
				status: 'active',
				condition: 90,
				aircraft_models: { capacity: 180 }
			}),
			userFleetAircraftFromMap({
				id: 'a2',
				status: 'active',
				condition: 20,
				aircraft_models: { capacity: 180 }
			}),
			userFleetAircraftFromMap({
				id: 'a3',
				status: 'active',
				condition: 90,
				acquisition_type: 'lease',
				aircraft_models: { capacity: 180 }
			})
		];
		const s = buildOverviewSnapshot(baseInputs({ fleet }));
		expect(s.totalFleetCount).toBe(3);
		expect(s.readyFleetCount).toBe(2); // a1 + a3
		expect(s.groundedCount).toBe(1); // a2 below 40
		expect(s.idleReadyFleetCount).toBe(2); // none assigned
		expect(s.leasedCount).toBe(1);
	});

	it('escalates bankruptcy risk correctly', () => {
		// cash at/below -2,000,000 (threshold/2.5) → critical
		expect(
			buildOverviewSnapshot(baseInputs({ sim: sim({ cashBalance: -3_000_000 }) }))
				.bankruptcyRiskLevel
		).toBe(2);
		// negative but above critical → warning
		expect(
			buildOverviewSnapshot(baseInputs({ sim: sim({ cashBalance: -100_000 }) })).bankruptcyRiskLevel
		).toBe(1);
		// positive → none
		expect(
			buildOverviewSnapshot(baseInputs({ sim: sim({ cashBalance: 1_000_000 }) }))
				.bankruptcyRiskLevel
		).toBe(0);
	});

	it('flags a route that needs assignment as risky and top risk', () => {
		const routes = [userRouteFromMap({ id: 'r1', origin_iata: 'SIN', destination_iata: 'KUL' })];
		const s = buildOverviewSnapshot(baseInputs({ routes }));
		expect(s.riskyRoutes).toBe(1);
		expect(s.topRouteRiskLabel).toBe('SIN → KUL');
	});

	it('adds a repair priority when aircraft are grounded', () => {
		const fleet = [
			userFleetAircraftFromMap({
				id: 'a1',
				status: 'active',
				condition: 10,
				aircraft_models: { capacity: 180 }
			})
		];
		const s = buildOverviewSnapshot(baseInputs({ fleet }));
		expect(s.priorities.some((p) => p.label === 'Repair fleet' && p.navigateToFleet)).toBe(true);
	});
});

describe('financeTotals', () => {
	it('separates revenue, lease and operations', () => {
		const totals = financeTotals([
			bankTransactionFromMap({ transaction_type: 'credit', amount: 1000 }),
			bankTransactionFromMap({
				transaction_type: 'debit',
				ifrs_subcategory: 'aircraft_lease',
				amount: 300
			}),
			bankTransactionFromMap({ transaction_type: 'debit', ifrs_subcategory: 'fuel', amount: 700 })
		]);
		expect(totals).toEqual({
			totalRevenue: 1000,
			totalExpense: 1000,
			totalLease: 300,
			totalOperations: 700
		});
	});
});
