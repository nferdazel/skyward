/**
 * Penyimpan token JWT skyward-api.
 *
 * Abstrak agar mudah di-mock; implementasi produksi memakai `localStorage`
 * (klien statis, tidak ada cookie sesi server). Port dari Flutter
 * `AuthTokenStore` / `SharedPrefsAuthTokenStore`.
 */
export interface AuthTokenStore {
	read(): string | null;
	write(token: string): void;
	clear(): void;
}

const TOKEN_KEY = 'skyward_api_token';

export class LocalStorageAuthTokenStore implements AuthTokenStore {
	read(): string | null {
		try {
			return localStorage.getItem(TOKEN_KEY);
		} catch {
			// localStorage bisa dilarang (private mode); anggap tanpa sesi.
			return null;
		}
	}

	write(token: string): void {
		try {
			localStorage.setItem(TOKEN_KEY, token);
		} catch {
			/* diabaikan: sesi tidak persisten, tapi app tetap jalan */
		}
	}

	clear(): void {
		try {
			localStorage.removeItem(TOKEN_KEY);
		} catch {
			/* diabaikan */
		}
	}
}
