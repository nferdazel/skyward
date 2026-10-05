import { describe, expect, it } from 'vitest';
import { env } from './env';

describe('env', () => {
	it('defaults apiBaseUrl to the local backend when unset', () => {
		// VITE_SKYWARD_API_URL tidak diset di test → fallback dev.
		expect(env.apiBaseUrl).toBe('http://localhost:8090');
	});
});
