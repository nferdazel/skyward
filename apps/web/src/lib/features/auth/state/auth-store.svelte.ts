import type { AuthGateway, AuthSession } from '../data/auth-gateway';
import type { AppUser } from '../domain/user';

export type AuthStatus = 'unknown' | 'unauthenticated' | 'authenticating' | 'authenticated';

/**
 * State auth (Svelte 5 runes). Pemilik tunggal status sesi.
 *
 * - `autoLogin()` saat start memulihkan sesi dari token tersimpan.
 * - `logout()` membersihkan token dan sesi.
 * - `onUnauthorized` global memanggil `logout()` (did aftarkan saat start).
 */
export class AuthStore {
	status = $state<AuthStatus>('unknown');
	user = $state<AppUser | null>(null);
	error = $state<string | null>(null);

	constructor(private readonly gateway: AuthGateway) {}

	get isAuthenticated(): boolean {
		return this.status === 'authenticated' && this.user !== null;
	}

	private apply(session: AuthSession): void {
		this.user = session.user;
		this.status = 'authenticated';
		this.error = null;
	}

	async autoLogin(): Promise<void> {
		const session = await this.gateway.restoreSession();
		if (session) {
			this.apply(session);
		} else {
			this.status = 'unauthenticated';
		}
	}

	async login(username: string, password: string): Promise<boolean> {
		this.status = 'authenticating';
		this.error = null;
		try {
			this.apply(await this.gateway.login({ username, password }));
			return true;
		} catch (err) {
			this.status = 'unauthenticated';
			this.error = err instanceof Error ? err.message : String(err);
			return false;
		}
	}

	async register(input: {
		username: string;
		password: string;
		companyName: string;
		ceoName: string;
	}): Promise<boolean> {
		this.status = 'authenticating';
		this.error = null;
		try {
			this.apply(await this.gateway.register(input));
			return true;
		} catch (err) {
			this.status = 'unauthenticated';
			this.error = err instanceof Error ? err.message : String(err);
			return false;
		}
	}

	async resetPassword(input: {
		username: string;
		newPassword: string;
		companyName?: string;
		ceoName?: string;
		hqAirportIata?: string;
	}): Promise<boolean> {
		this.error = null;
		try {
			await this.gateway.resetPassword(input);
			return true;
		} catch (err) {
			this.error = err instanceof Error ? err.message : String(err);
			return false;
		}
	}

	logout(): void {
		this.gateway.logout();
		this.user = null;
		this.status = 'unauthenticated';
		this.error = null;
	}
}
