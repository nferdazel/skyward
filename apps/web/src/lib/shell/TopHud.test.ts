import { render, screen, within } from '@testing-library/svelte';
import { describe, expect, it } from 'vitest';
import TopHud from './TopHud.svelte';
import type { AppUser } from '$lib/features/auth/domain/user';
import type { SimulationState } from '$lib/features/simulation/state/simulation-store.svelte';
import { NotificationStore } from '$lib/features/notification/state/notification-store.svelte';

function user(over: Partial<AppUser> = {}): AppUser {
	return {
		id: 'u1',
		username: 'fredi',
		companyName: 'Skyward Air',
		ceoName: 'Fredi',
		netWorth: 0,
		gameCurrentTime: '2043-06-15T12:00:00Z',
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
		gameTime: '2043-06-15T12:00:00Z',
		cashBalance: 25_000_000,
		fuelPricePerLiter: 0.85,
		gameSpeedMultiplier: 1,
		isSyncing: false,
		lastFlightsRun: 12,
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

describe('TopHud', () => {
	it('renders the company (uppercase), CEO and the game date from the sim clock', () => {
		render(TopHud, { props: { user: user(), sim: sim() } });

		expect(screen.getByText('SKYWARD AIR')).toBeInTheDocument();
		expect(screen.getByText('CEO Fredi')).toBeInTheDocument();
		expect(screen.getByText('2043-06-15')).toBeInTheDocument();
	});

	it('shows the unread badge from the notification store', () => {
		const notifications = new NotificationStore();
		notifications.push({ type: 'info', title: 'A' });
		notifications.push({ type: 'warning', title: 'B' });
		notifications.push({ type: 'success', title: 'C' });
		render(TopHud, { props: { user: user(), sim: sim(), notifications } });

		const bell = screen.getByRole('button', { name: 'Notifications' });
		expect(within(bell).getByText('3')).toBeInTheDocument();
	});

	it('renders without notifications (no unread badge)', () => {
		render(TopHud, { props: { user: user(), sim: sim() } });

		const bell = screen.getByRole('button', { name: 'Notifications' });
		expect(bell.textContent?.trim()).toBe('');
	});

	it('opens the panel on bell click and marks notifications read', async () => {
		const notifications = new NotificationStore();
		notifications.push({ type: 'info', title: 'Low cash' });
		render(TopHud, { props: { user: user(), sim: sim(), notifications } });

		await screen.getByRole('button', { name: 'Notifications' }).click();

		expect(screen.getByRole('dialog', { name: 'Notifications' })).toBeInTheDocument();
		expect(notifications.unreadCount).toBe(0);
	});
});
