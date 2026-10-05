import { ApiError } from '$lib/core/api/errors';
import type { ApiClient } from '$lib/core/api/api-client';
import type { AuthTokenStore } from '$lib/core/api/auth-token-store';
import { userFromMap, type AppUser } from '../domain/user';

export interface AuthSession {
	user: AppUser;
	token: string;
}

/**
 * Mirror `public.normalize_username` (SQL): lowercase → trim → run karakter
 * non `[a-z0-9._-]` menjadi `-` → buang `-` di ujung.
 *
 * Login server melakukan exact match (case-sensitive) sedangkan register
 * menormalisasi; jadi klien harus menormalisasi sebelum login agar username
 * non-lowercase tetap menemukan akun.
 */
export function normalizeUsername(username: string): string {
	return username
		.trim()
		.toLowerCase()
		.replace(/[^a-z0-9._-]+/g, '-')
		.replace(/^-+|-+$/g, '');
}

export class AuthGatewayError extends Error {
	readonly code: string;
	constructor(message: string, code = 'internal') {
		super(message);
		this.name = 'AuthGatewayError';
		this.code = code;
	}
}

function wrap(err: unknown): AuthGatewayError {
	if (err instanceof ApiError) return new AuthGatewayError(err.message, err.code);
	return new AuthGatewayError(err instanceof Error ? err.message : String(err));
}

/**
 * Auth melalui skyward-api (Go REST + JWT). Port dari `GoAuthGateway`.
 *
 * Kontrak (`apps/api/internal/handler/auth.go`):
 * - `POST /auth/register` {username, password, companyName, ceoName} → {token, user}
 * - `POST /auth/login` {username, password} → {token, user}
 * - `GET /auth/me` (Bearer) → {user}
 * - logout = hapus JWT lokal (tidak ada sesi server)
 */
export class AuthGateway {
	constructor(
		private readonly api: ApiClient,
		private readonly tokenStore: AuthTokenStore
	) {}

	async restoreSession(): Promise<AuthSession | null> {
		const token = this.tokenStore.read();
		if (!token) return null;
		try {
			const data = await this.api.get<Record<string, unknown>>('/auth/me');
			return { user: userFromMap((data.user as Record<string, unknown>) ?? data), token };
		} catch (err) {
			if (err instanceof ApiError && err.isUnauthorized) {
				this.tokenStore.clear();
				return null;
			}
			throw wrap(err);
		}
	}

	async register(input: {
		username: string;
		password: string;
		companyName: string;
		ceoName: string;
	}): Promise<AuthSession> {
		try {
			const data = await this.api.post<Record<string, unknown>>('/auth/register', {
				username: input.username,
				password: input.password,
				companyName: input.companyName,
				ceoName: input.ceoName
			});
			return this.sessionFromResponse(data);
		} catch (err) {
			throw wrap(err);
		}
	}

	async login(input: { username: string; password: string }): Promise<AuthSession> {
		try {
			const data = await this.api.post<Record<string, unknown>>('/auth/login', {
				username: normalizeUsername(input.username),
				password: input.password
			});
			return this.sessionFromResponse(data);
		} catch (err) {
			throw wrap(err);
		}
	}

	logout(): void {
		this.tokenStore.clear();
	}

	async resetPassword(input: {
		username: string;
		newPassword: string;
		companyName?: string;
		ceoName?: string;
		hqAirportIata?: string;
	}): Promise<void> {
		try {
			await this.api.post('/auth/reset-password', {
				username: normalizeUsername(input.username),
				newPassword: input.newPassword,
				companyName: input.companyName ?? '',
				ceoName: input.ceoName ?? '',
				hqAirportIata: input.hqAirportIata ?? ''
			});
		} catch (err) {
			throw wrap(err);
		}
	}

	private sessionFromResponse(data: Record<string, unknown>): AuthSession {
		const token = data.token;
		if (typeof token !== 'string' || !token) {
			throw new AuthGatewayError('Authentication failed: no token.');
		}
		const userPayload = data.user;
		if (!userPayload || typeof userPayload !== 'object') {
			throw new AuthGatewayError('Authentication failed: no user data.');
		}
		this.tokenStore.write(token);
		return { user: userFromMap(userPayload as Record<string, unknown>), token };
	}
}
