import { ApiError, type ApiErrorCode } from './errors';
import type { AuthTokenStore } from './auth-token-store';

export type Query = Record<string, string | number | boolean | null | undefined>;

/**
 * HTTP client untuk skyward-api (Go, REST).
 *
 * - Base URL disuntikkan oleh pemanggil (dari `env.apiBaseUrl`).
 * - Menyuntikkan header `Authorization: Bearer <token>` bila token store ada.
 * - Mem-parse error envelope Go: `{"error":{"code","message"}}` menjadi
 *   `ApiError`; kegagalan transport dipetakan ke `network`/`timeout`.
 *
 * Port dari Flutter `ApiClient`.
 */
export class ApiClient {
	private readonly baseUrl: string;
	private readonly tokenStore?: AuthTokenStore;
	private readonly timeoutMs: number;

	/** Dipanggil saat respons 401 / error `unauthorized` (mis. logout otomatis). */
	onUnauthorized?: () => void;

	constructor(opts: {
		baseUrl: string;
		tokenStore?: AuthTokenStore;
		timeoutMs?: number;
		onUnauthorized?: () => void;
	}) {
		this.baseUrl = opts.baseUrl.replace(/\/+$/, '');
		this.tokenStore = opts.tokenStore;
		this.timeoutMs = opts.timeoutMs ?? 20_000;
		this.onUnauthorized = opts.onUnauthorized;
	}

	private buildUrl(path: string, query?: Query): string {
		const cleanPath = path.startsWith('/') ? path : `/${path}`;
		const url = new URL(`${this.baseUrl}${cleanPath}`);
		if (query) {
			for (const [key, value] of Object.entries(query)) {
				if (value !== null && value !== undefined) {
					url.searchParams.set(key, String(value));
				}
			}
		}
		return url.toString();
	}

	private headers(json: boolean): HeadersInit {
		const headers: Record<string, string> = { Accept: 'application/json' };
		if (json) headers['Content-Type'] = 'application/json';
		const token = this.tokenStore?.read();
		if (token) headers['Authorization'] = `Bearer ${token}`;
		return headers;
	}

	get<T = unknown>(path: string, query?: Query): Promise<T> {
		return this.send<T>(() =>
			fetch(this.buildUrl(path, query), { method: 'GET', headers: this.headers(false) })
		);
	}

	post<T = unknown>(path: string, body?: unknown): Promise<T> {
		return this.send<T>(() =>
			fetch(this.buildUrl(path), {
				method: 'POST',
				headers: this.headers(true),
				body: body === undefined ? undefined : JSON.stringify(body)
			})
		);
	}

	patch<T = unknown>(path: string, body?: unknown): Promise<T> {
		return this.send<T>(() =>
			fetch(this.buildUrl(path), {
				method: 'PATCH',
				headers: this.headers(true),
				body: body === undefined ? undefined : JSON.stringify(body)
			})
		);
	}

	delete<T = unknown>(path: string, body?: unknown): Promise<T> {
		return this.send<T>(() =>
			fetch(this.buildUrl(path), {
				method: 'DELETE',
				headers: this.headers(true),
				body: body === undefined ? undefined : JSON.stringify(body)
			})
		);
	}

	private async send<T>(request: () => Promise<Response>): Promise<T> {
		const controller = new AbortController();
		const timer = setTimeout(() => controller.abort(), this.timeoutMs);
		let response: Response;
		try {
			response = await request();
		} catch (err) {
			clearTimeout(timer);
			if (err instanceof DOMException && err.name === 'AbortError') {
				throw new ApiError('Request timed out.', 'timeout');
			}
			throw new ApiError(err instanceof Error ? err.message : String(err), 'network');
		}
		clearTimeout(timer);

		const body = await this.parseBody(response);
		if (response.ok) return body as T;
		throw this.errorFromResponse(response, body);
	}

	private async parseBody(response: Response): Promise<unknown> {
		const text = await response.text();
		if (!text) return null;
		try {
			return JSON.parse(text);
		} catch {
			return text;
		}
	}

	private errorFromResponse(response: Response, body: unknown): ApiError {
		let message = `Request failed (HTTP ${response.status}).`;
		let code: ApiErrorCode = 'internal';

		if (body && typeof body === 'object') {
			const maybe = body as Record<string, unknown>;
			const error = maybe.error;
			if (error && typeof error === 'object') {
				const envelope = error as Record<string, unknown>;
				if (typeof envelope.message === 'string') message = envelope.message;
				if (typeof envelope.code === 'string') code = envelope.code as ApiErrorCode;
			} else if (typeof maybe.message === 'string') {
				message = maybe.message;
			}
		} else if (typeof body === 'string' && body) {
			message = body;
		}

		const isUnauthorized = response.status === 401 || code === 'unauthorized';
		if (isUnauthorized) {
			code = 'unauthorized';
			this.onUnauthorized?.();
		}
		return new ApiError(message, code, response.status);
	}
}
