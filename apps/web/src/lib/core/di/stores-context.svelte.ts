import type { AppStores } from './app-stores.svelte';
import type { AuthStore } from '$lib/features/auth/state/auth-store.svelte';

/**
 * Holder stores aplikasi (per sesi).
 *
 * Sengaja BUKAN Svelte context: `setContext` harus dipanggil saat init
 * komponen, sedangkan stores baru dibuat setelah auth berhasil (di dalam
 * `$effect`). Context yang di-set di effect tak akan pernah terbaca anak yang
 * sudah mengevaluasi `getContext` lebih dulu — itulah penyebab error
 * "AppStores tidak tersedia di context ini".
 *
 * Sebagai gantinya, holder reaktif module-level: layout mengisi `stores` saat
 * sesi siap, halaman membaca reaktif. `null` = belum ada sesi.
 */
class StoresHolder {
	stores = $state<AppStores | null>(null);
	auth = $state<AuthStore | null>(null);
}

export const appStores = new StoresHolder();

/** Setelah sesi siap (dipanggil layout). */
export function setAppStores(stores: AppStores): void {
	appStores.stores = stores;
}

/** Dipanggil layout saat logout untuk melepas referensi. */
export function clearAppStores(): void {
	appStores.stores = null;
}

export function setAuthStoreRef(auth: AuthStore): void {
	appStores.auth = auth;
}

/** Ambil stores; melempar bila dipanggil sebelum sesi siap. */
export function requireAppStores(): AppStores {
	const stores = appStores.stores;
	if (!stores) throw new Error('AppStores belum siap (belum ada sesi)');
	return stores;
}
