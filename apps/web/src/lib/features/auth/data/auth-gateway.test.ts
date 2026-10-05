import { describe, expect, it, vi } from 'vitest';
import { AuthGateway, normalizeUsername } from './auth-gateway';
import type { ApiClient } from '$lib/core/api/api-client';
import type { AuthTokenStore } from '$lib/core/api/auth-token-store';

function makeTokenStore(): AuthTokenStore & { value: string | null } {
	return {
		value: null as string | null,
		read() {
			return this.value;
		},
		write(t: string) {
			this.value = t;
		},
		clear() {
			this.value = null;
		}
	};
}

describe('normalizeUsername', () => {
	it('mirrors the SQL normalize_username', () => {
		expect(normalizeUsername('  FrediNix  ')).toBe('fredinix');
		expect(normalizeUsername('a b/c')).toBe('a-b-c');
		expect(normalizeUsername('--a--')).toBe('a');
		expect(normalizeUsername('a.b_c-d')).toBe('a.b_c-d');
	});
});

describe('AuthGateway', () => {
	it('sends exactly the register keys and stores the token', async () => {
		const post = vi.fn().mockResolvedValue({
			token: 'jwt-1',
			user: { id: 'u1', username: 'fredi', company_name: 'Sky' }
		});
		const store = makeTokenStore();
		const gateway = new AuthGateway({ post } as unknown as ApiClient, store);

		const session = await gateway.register({
			username: 'fredi',
			password: 'pw',
			companyName: 'Sky',
			ceoName: 'Fredi'
		});

		expect(post).toHaveBeenCalledWith('/auth/register', {
			username: 'fredi',
			password: 'pw',
			companyName: 'Sky',
			ceoName: 'Fredi'
		});
		expect(session.user.id).toBe('u1');
		expect(store.value).toBe('jwt-1');
	});

	it('normalises the username before login', async () => {
		const post = vi.fn().mockResolvedValue({
			token: 'jwt-2',
			user: { id: 'u1', username: 'fredi' }
		});
		const gateway = new AuthGateway({ post } as unknown as ApiClient, makeTokenStore());

		await gateway.login({ username: '  FreDi  ', password: 'pw' });

		expect(post).toHaveBeenCalledWith('/auth/login', { username: 'fredi', password: 'pw' });
	});

	it('throws when the response has no token', async () => {
		const post = vi.fn().mockResolvedValue({ user: { id: 'u1' } });
		const gateway = new AuthGateway({ post } as unknown as ApiClient, makeTokenStore());

		await expect(gateway.login({ username: 'a', password: 'b' })).rejects.toThrow('no token');
	});

	it('clears the token store on logout', () => {
		const store = makeTokenStore();
		store.value = 'jwt';
		const gateway = new AuthGateway({} as unknown as ApiClient, store);

		gateway.logout();

		expect(store.value).toBeNull();
	});
});
