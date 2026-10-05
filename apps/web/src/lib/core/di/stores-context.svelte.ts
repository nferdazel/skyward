import { getContext, setContext } from 'svelte';
import type { AppStores } from './app-stores.svelte';

const STORES_KEY = Symbol('skyward.stores');

export function setAppStores(stores: AppStores): void {
	setContext(STORES_KEY, stores);
}

export function getAppStores(): AppStores {
	const stores = getContext<AppStores>(STORES_KEY);
	if (!stores) throw new Error('AppStores tidak tersedia di context ini');
	return stores;
}
