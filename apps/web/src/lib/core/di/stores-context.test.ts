import { describe, expect, it } from 'vitest';
import { appStores, setAppStores, clearAppStores, requireAppStores } from './stores-context.svelte';
import type { AppStores } from './app-stores.svelte';

describe('appStores holder', () => {
	it('is empty before a session is set', () => {
		clearAppStores();
		expect(appStores.stores).toBeNull();
	});

	it('requires a session before exposing stores', () => {
		clearAppStores();
		expect(() => requireAppStores()).toThrow('AppStores belum siap');
	});

	it('exposes stores after setAppStores and clears on logout', () => {
		const fake = { marker: true } as unknown as AppStores;
		setAppStores(fake);
		// $state membungkus objek dalam proxy reaktif → bandingkan nilai, bukan identitas.
		expect(requireAppStores()).toStrictEqual(fake);
		clearAppStores();
		expect(appStores.stores).toBeNull();
	});
});
