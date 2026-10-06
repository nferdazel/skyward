import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import OverviewTab from './OverviewTab.svelte';
import type { AppStores } from '$lib/core/di/app-stores.svelte';
import type { AppUser } from '$lib/features/auth/domain/user';
import { emptyFinanceSnapshot } from '$lib/features/finance/domain/finance-snapshot';
import type { SimulationState } from '$lib/features/simulation/state/simulation-store.svelte';

const user: AppUser = {
	id: 'u1',
	username: 'new',
	companyName: 'New Air',
	ceoName: 'N',
	netWorth: 25_000_000,
	gameCurrentTime: '2043-01-01T00:00:00Z',
	autoGroundingThreshold: 40,
	hqAirportIata: 'SIN',
	operationalStatus: 'Active',
	consecutiveNegativeDays: 0,
	recoveryStreakDays: 0,
	onboardingCompleted: true,
	actorType: 'REAL'
};

const sim: SimulationState = {
	gameTime: '2043-01-01T00:00:00Z',
	cashBalance: 25_000_000,
	fuelPricePerLiter: 0.85,
	gameSpeedMultiplier: 1,
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
	errorMessage: null
};

function makeStores(over: { events?: unknown[]; achievements?: unknown[] } = {}): AppStores {
	return {
		fleet: { state: { loading: false, aircraft: [], catalog: [], error: null } },
		routes: {
			state: {
				loading: false,
				routes: [],
				airports: [],
				availableFleet: [],
				assessments: {},
				groundingThreshold: 40,
				error: null
			}
		},
		finance: {
			state: {
				loading: false,
				snapshot: emptyFinanceSnapshot(),
				history: [],
				transactions: [],
				error: null
			}
		},
		leaderboard: { state: { loading: false, entries: [], insights: null, error: null } },
		events: { state: { loading: false, events: over.events ?? [], error: null } },
		achievements: { state: { loading: false, achievements: over.achievements ?? [], error: null } },
		simulation: { state: sim }
	} as unknown as AppStores;
}

describe('OverviewTab', () => {
	it('shows the Get started guide for a brand-new airline', () => {
		render(OverviewTab, { props: { stores: makeStores(), user, onnavigate: vi.fn() } });
		expect(screen.getByText('Get started')).toBeInTheDocument();
		expect(screen.getByText('Acquire an aircraft')).toBeInTheDocument();
		expect(screen.queryByText('Command deck')).toBeNull();
	});

	it('shows active world events when present', () => {
		const events = [
			{
				id: 'e1',
				eventType: 'weather',
				title: 'Weather Disruption',
				description: '',
				effectType: 'demand',
				effectTarget: '',
				effectValue: 1,
				startGameTime: '',
				endGameTime: '',
				isActive: true
			}
		];
		render(OverviewTab, { props: { stores: makeStores({ events }), user, onnavigate: vi.fn() } });
		expect(screen.getByText('Active world events')).toBeInTheDocument();
		expect(screen.getByText('Weather Disruption')).toBeInTheDocument();
	});
});
