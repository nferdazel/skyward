import { describe, expect, it, vi } from 'vitest';
import { AuthStore } from './auth-store.svelte';
import type { AuthGateway, AuthSession } from '../data/auth-gateway';

const session: AuthSession = {
	token: 'jwt',
	user: {
		id: 'u1',
		username: 'fredi',
		companyName: 'Sky',
		ceoName: 'Fredi',
		netWorth: 0,
		gameCurrentTime: '2030-01-01T00:00:00Z',
		autoGroundingThreshold: 30,
		hqAirportIata: 'SIN',
		operationalStatus: 'Active',
		consecutiveNegativeDays: 0,
		recoveryStreakDays: 0,
		onboardingCompleted: false,
		actorType: 'REAL'
	}
};

function makeGateway(overrides: Partial<AuthGateway>): AuthGateway {
	return {
		restoreSession: vi.fn().mockResolvedValue(null),
		login: vi.fn(),
		register: vi.fn(),
		logout: vi.fn(),
		resetPassword: vi.fn(),
		...overrides
	} as unknown as AuthGateway;
}

describe('AuthStore', () => {
	it('autoLogin restores an existing session', async () => {
		const store = new AuthStore(
			makeGateway({ restoreSession: vi.fn().mockResolvedValue(session) })
		);

		await store.autoLogin();

		expect(store.isAuthenticated).toBe(true);
		expect(store.user?.id).toBe('u1');
	});

	it('autoLogin falls back to unauthenticated when there is no session', async () => {
		const store = new AuthStore(makeGateway({ restoreSession: vi.fn().mockResolvedValue(null) }));

		await store.autoLogin();

		expect(store.status).toBe('unauthenticated');
		expect(store.user).toBeNull();
	});

	it('login success stores the session and returns true', async () => {
		const store = new AuthStore(makeGateway({ login: vi.fn().mockResolvedValue(session) }));

		const ok = await store.login('fredi', 'pw');

		expect(ok).toBe(true);
		expect(store.isAuthenticated).toBe(true);
	});

	it('login failure sets an error and returns false', async () => {
		const store = new AuthStore(
			makeGateway({ login: vi.fn().mockRejectedValue(new Error('bad credentials')) })
		);

		const ok = await store.login('fredi', 'wrong');

		expect(ok).toBe(false);
		expect(store.status).toBe('unauthenticated');
		expect(store.error).toBe('bad credentials');
	});

	it('logout clears the session and calls the gateway', () => {
		const logout = vi.fn();
		const store = new AuthStore(makeGateway({ logout }));
		store.user = session.user;
		store.status = 'authenticated';

		store.logout();

		expect(logout).toHaveBeenCalledOnce();
		expect(store.user).toBeNull();
		expect(store.status).toBe('unauthenticated');
	});
});
