import { afterEach, describe, expect, it, vi } from 'vitest';
import { ApiClient } from './api-client';
import { ApiError } from './errors';
import type { AuthTokenStore } from './auth-token-store';

function jsonResponse(body: unknown, status = 200): Response {
	return new Response(JSON.stringify(body), {
		status,
		headers: { 'Content-Type': 'application/json' }
	});
}

const tokenStore: AuthTokenStore = {
	read: () => 'test-token',
	write: () => {},
	clear: () => {}
};

describe('ApiClient', () => {
	afterEach(() => vi.restoreAllMocks());

	it('injects the bearer token and parses a successful JSON body', async () => {
		const fetchMock = vi
			.spyOn(globalThis, 'fetch')
			.mockResolvedValue(jsonResponse({ id: 'u1', username: 'fredi' }));
		const client = new ApiClient({ baseUrl: 'https://api.example/skyward', tokenStore });

		const result = await client.get<{ id: string }>('/auth/me');

		expect(result.id).toBe('u1');
		const [, init] = fetchMock.mock.calls[0];
		expect((init?.headers as Record<string, string>)['Authorization']).toBe('Bearer test-token');
	});

	it('omits the Authorization header when there is no token', async () => {
		const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValue(jsonResponse({ ok: true }));
		const client = new ApiClient({
			baseUrl: 'https://api.example',
			tokenStore: { read: () => null, write: () => {}, clear: () => {} }
		});

		await client.get('/health');

		const [, init] = fetchMock.mock.calls[0];
		expect((init?.headers as Record<string, string>)['Authorization']).toBeUndefined();
	});

	it('maps the Go error envelope to ApiError', async () => {
		vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			jsonResponse({ error: { code: 'validation', message: 'aircraft required' } }, 400)
		);
		const client = new ApiClient({ baseUrl: 'https://api.example' });

		await expect(client.post('/routes/1/assign', {})).rejects.toMatchObject({
			code: 'validation',
			message: 'aircraft required',
			statusCode: 400
		});
	});

	it('calls onUnauthorized and marks the error on a 401', async () => {
		vi.spyOn(globalThis, 'fetch').mockResolvedValue(
			jsonResponse({ error: { code: 'unauthorized', message: 'no session' } }, 401)
		);
		const onUnauthorized = vi.fn();
		const client = new ApiClient({ baseUrl: 'https://api.example', onUnauthorized });

		const error = await client.get('/auth/me').catch((e: unknown) => e);

		expect(error).toBeInstanceOf(ApiError);
		expect((error as ApiError).isUnauthorized).toBe(true);
		expect(onUnauthorized).toHaveBeenCalledOnce();
	});

	it('maps a transport failure to a network error', async () => {
		vi.spyOn(globalThis, 'fetch').mockRejectedValue(new TypeError('Failed to fetch'));
		const client = new ApiClient({ baseUrl: 'https://api.example' });

		await expect(client.get('/fleet')).rejects.toMatchObject({ code: 'network' });
	});

	it('serialises query parameters, skipping null and undefined', async () => {
		const fetchMock = vi.spyOn(globalThis, 'fetch').mockResolvedValue(jsonResponse([]));
		const client = new ApiClient({ baseUrl: 'https://api.example' });

		await client.get('/routes/assess', { price: 120, freq: null, note: undefined });

		const [url] = fetchMock.mock.calls[0];
		expect(String(url)).toBe('https://api.example/routes/assess?price=120');
	});

	it('passes an AbortSignal to fetch and times out when the request hangs', async () => {
		vi.useFakeTimers();
		// fetch yang menggantung sampai sinyal abort (meniru server tak merespons).
		const fetchMock = vi.spyOn(globalThis, 'fetch').mockImplementation(
			(_url, init) =>
				new Promise((_resolve, reject) => {
					init?.signal?.addEventListener('abort', () =>
						reject(new DOMException('aborted', 'AbortError'))
					);
				})
		);
		const client = new ApiClient({ baseUrl: 'https://api.example', timeoutMs: 1000 });

		const pending = client.get('/fleet');
		const assertion = expect(pending).rejects.toMatchObject({ code: 'timeout' });
		await vi.advanceTimersByTimeAsync(1000);
		await assertion;

		// Bukti sinyal benar-benar diteruskan ke fetch.
		const [, init] = fetchMock.mock.calls[0];
		expect(init?.signal).toBeInstanceOf(AbortSignal);
		vi.useRealTimers();
	});
});
