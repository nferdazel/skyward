import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import LeaderboardView from './LeaderboardView.svelte';
import type { LeaderboardStore } from '../state/leaderboard-store.svelte';
import { leaderboardEntryFromMap } from '../domain/leaderboard-models';

function makeStore(over: Partial<LeaderboardStore['state']> = {}): LeaderboardStore {
	return {
		state: {
			loading: false,
			entries: [
				leaderboardEntryFromMap({
					id: 'u1',
					company_name: 'Ace Air',
					net_worth: 9000,
					is_bot: true
				}),
				leaderboardEntryFromMap({ id: 'me', company_name: 'My Air', net_worth: 4200 })
			],
			insights: null,
			error: null,
			...over
		},
		load: vi.fn(),
		loadCompetitor: vi.fn()
	} as unknown as LeaderboardStore;
}

describe('LeaderboardView', () => {
	it('lists entries sorted by net worth with an AI badge', () => {
		render(LeaderboardView, { props: { store: makeStore(), currentUserId: 'me' } });
		expect(screen.getByText('Ace Air')).toBeInTheDocument();
		expect(screen.getByText('AI')).toBeInTheDocument();
		expect(screen.getByText('YOU')).toBeInTheDocument();
		expect(screen.getByText('$9,000')).toBeInTheDocument();
	});

	it('shows the competitor-intel prompt before a selection', () => {
		render(LeaderboardView, { props: { store: makeStore() } });
		expect(screen.getByText('Select a competitor to see intel.')).toBeInTheDocument();
	});
});
