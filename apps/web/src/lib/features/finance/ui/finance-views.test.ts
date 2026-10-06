import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import FinanceView from './FinanceView.svelte';
import LeaderboardView from '$lib/features/leaderboard/ui/LeaderboardView.svelte';
import SettingsView from '$lib/features/settings/ui/SettingsView.svelte';
import type { FinanceStore } from '../state/finance-store.svelte';
import type { LeaderboardStore } from '$lib/features/leaderboard/state/leaderboard-store.svelte';
import type { SettingsStore } from '$lib/features/settings/state/settings-store.svelte';
import type { AuthStore } from '$lib/features/auth/state/auth-store.svelte';
import { bankTransactionFromMap } from '$lib/features/bank/domain/bank-models';
import { financeSnapshotFromMap } from '../domain/finance-snapshot';
import { leaderboardEntryFromMap } from '$lib/features/leaderboard/domain/leaderboard-models';

describe('FinanceView', () => {
	it('renders KPI zones from the snapshot', () => {
		const store = {
			state: {
				loading: false,
				snapshot: financeSnapshotFromMap({ cash: 1234, net_worth: 9999, rolling_revenue_30d: 500 }),
				history: [],
				transactions: [],
				error: null
			},
			load: vi.fn(),
			refresh: vi.fn()
		} as unknown as FinanceStore;

		render(FinanceView, { props: { store } });
		expect(screen.getByText('$1,234')).toBeInTheDocument();
		expect(screen.getByText('$9,999')).toBeInTheDocument();
		expect(screen.getAllByText('$500').length).toBeGreaterThan(0);
	});

	it('shows the IFRS income statement from transactions', async () => {
		const store = {
			state: {
				loading: false,
				snapshot: financeSnapshotFromMap({}),
				history: [],
				transactions: [
					bankTransactionFromMap({
						transaction_type: 'credit',
						ifrs_subcategory: 'ticket_revenue',
						amount: 2000
					}),
					bankTransactionFromMap({
						transaction_type: 'debit',
						ifrs_subcategory: 'fuel',
						amount: 500
					})
				],
				error: null
			},
			load: vi.fn(),
			refresh: vi.fn()
		} as unknown as FinanceStore;

		render(FinanceView, { props: { store } });
		await screen.getByRole('tab', { name: 'IFRS report' }).click();
		expect(screen.getAllByText('$2,000').length).toBeGreaterThan(0);
		expect(screen.getAllByText('$1,500').length).toBeGreaterThan(0); // net income
	});
});

describe('LeaderboardView', () => {
	it('lists entries and shows an AI badge for bots', () => {
		const store = {
			state: {
				loading: false,
				entries: [
					leaderboardEntryFromMap({ id: 'u1', company_name: 'Ace', net_worth: 4200, is_bot: true })
				],
				insights: null,
				error: null
			},
			load: vi.fn(),
			loadCompetitor: vi.fn()
		} as unknown as LeaderboardStore;

		render(LeaderboardView, { props: { store } });
		expect(screen.getByText('Ace')).toBeInTheDocument();
		expect(screen.getByText('AI')).toBeInTheDocument();
		expect(screen.getByText('$4,200')).toBeInTheDocument();
	});
});

describe('SettingsView', () => {
	it('seeds the form from the authenticated user', () => {
		const store = {
			state: { loading: false, airports: [], uiScale: 1, error: null },
			load: vi.fn(),
			save: vi.fn(),
			reset: vi.fn(),
			deleteAccount: vi.fn()
		} as unknown as SettingsStore;
		const auth = {
			user: {
				companyName: 'Sky Air',
				hqAirportIata: 'SIN',
				autoGroundingThreshold: 45
			}
		} as unknown as AuthStore;

		render(SettingsView, { props: { store, auth } });
		expect((screen.getByDisplayValue('Sky Air') as HTMLInputElement).value).toBe('Sky Air');
		expect(screen.getByDisplayValue('SIN')).toBeInTheDocument();
		expect(screen.getByRole('button', { name: 'Reset airline' })).toBeInTheDocument();
	});
});
