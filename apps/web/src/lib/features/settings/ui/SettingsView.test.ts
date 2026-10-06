import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import SettingsView from './SettingsView.svelte';
import type { SettingsStore } from '../state/settings-store.svelte';
import type { AppUser } from '$lib/features/auth/domain/user';

const user: AppUser = {
	id: 'u1',
	username: 'fredi',
	companyName: 'Sky Air',
	ceoName: 'Fredi',
	netWorth: 0,
	gameCurrentTime: '2030-01-01T00:00:00Z',
	autoGroundingThreshold: 45,
	hqAirportIata: 'SIN',
	operationalStatus: 'Active',
	consecutiveNegativeDays: 0,
	recoveryStreakDays: 0,
	onboardingCompleted: true,
	actorType: 'REAL'
};

function makeStore(): SettingsStore {
	return {
		state: { loading: false, airports: [], uiScale: 1, error: null },
		load: vi.fn(),
		save: vi.fn(),
		reset: vi.fn(),
		deleteAccount: vi.fn()
	} as unknown as SettingsStore;
}

describe('SettingsView', () => {
	it('seeds the profile form from the user', () => {
		render(SettingsView, { props: { store: makeStore(), user, ondeleted: vi.fn() } });
		expect((screen.getByDisplayValue('Sky Air') as HTMLInputElement).value).toBe('Sky Air');
		expect(screen.getByDisplayValue('SIN')).toBeInTheDocument();
		expect(screen.getByRole('button', { name: 'Reset airline' })).toBeInTheDocument();
		expect(screen.getByRole('button', { name: 'Delete account' })).toBeInTheDocument();
	});

	it('requires typing DELETE to enable account deletion', async () => {
		render(SettingsView, { props: { store: makeStore(), user, ondeleted: vi.fn() } });
		await screen.getByRole('button', { name: 'Delete account' }).click();
		const del = screen.getByRole('button', { name: 'Delete' }) as HTMLButtonElement;
		expect(del.disabled).toBe(true);
	});
});
