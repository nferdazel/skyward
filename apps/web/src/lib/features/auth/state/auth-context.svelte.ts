import { getContext, setContext } from 'svelte';
import type { AuthStore } from '$lib/features/auth/state/auth-store.svelte';

const AUTH_KEY = Symbol('skyward.auth');

/** Sediakan AuthStore ke seluruh pohon komponen (dipanggil di root layout). */
export function setAuthStore(store: AuthStore): void {
	setContext(AUTH_KEY, store);
}

/** Ambil AuthStore dari context. */
export function getAuthStore(): AuthStore {
	const store = getContext<AuthStore>(AUTH_KEY);
	if (!store) throw new Error('AuthStore tidak tersedia di context ini');
	return store;
}
