import { ApiClient } from '../api/api-client';
import { ApiError } from '../api/errors';
import { LocalStorageAuthTokenStore } from '../api/auth-token-store';
import { env } from '../config/env';
import { RealtimeClient } from '../realtime/realtime-client';

/**
 * Wiring bersama aplikasi (pengganti Flutter `GatewayFactory`).
 *
 * Satu `ApiClient` dan satu `RealtimeClient` dipakai seluruh fitur. Modul ini
 * menyimpan instance tunggal (singleton) agar koneksi WS tidak berlipat dan
 * token dibaca dari satu tempat.
 *
 * Untuk test, gunakan `configureServices()` untuk menyuntik klien palsu, atau
 * `resetServices()`.
 */
class Services {
	apiClient!: ApiClient;
	realtimeClient!: RealtimeClient;
	private readonly tokenStore = new LocalStorageAuthTokenStore();

	constructor() {
		this.build();
	}

	private build(): void {
		this.apiClient = new ApiClient({
			baseUrl: env.apiBaseUrl,
			tokenStore: this.tokenStore,
			onUnauthorized: () => this.onUnauthorized?.()
		});
		this.realtimeClient = new RealtimeClient({
			baseUrl: env.apiBaseUrl,
			ticketFetcher: () => this.fetchRealtimeTicket()
		});
	}

	/** Handler global 401 (did aftarkan `AuthStore.logout` saat start). */
	onUnauthorized?: () => void;

	/**
	 * Tukar sesi aktif menjadi tiket WS sekali pakai (`POST /ws/ticket`).
	 * Null berarti belum ada sesi — bukan error, jangan reconnect.
	 */
	private async fetchRealtimeTicket(): Promise<string | null> {
		try {
			const res = await this.apiClient.post<{ ticket?: string }>('/ws/ticket');
			const ticket = res?.ticket;
			return ticket && ticket.length > 0 ? ticket : null;
		} catch (err) {
			if (err instanceof ApiError && err.isUnauthorized) return null;
			throw err;
		}
	}

	/** Suntik klien untuk test. */
	overrideApiClient(client: ApiClient): void {
		this.apiClient = client;
	}

	overrideRealtimeClient(client: RealtimeClient): void {
		this.realtimeClient = client;
	}

	reset(): void {
		this.realtimeClient.dispose();
		this.build();
	}
}

export const services = new Services();

/** Helper test: ganti instance global. */
export function configureServices(configure: (s: Services) => void): void {
	configure(services);
}

export function resetServices(): void {
	services.reset();
}
