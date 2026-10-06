<script lang="ts">
	import '$lib/core/theme/tokens.css';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { services } from '$lib/core/di/services';
	import { appStores } from '$lib/core/di/stores-context.svelte';
	import { createAppStores, type AppStores } from '$lib/core/di/app-stores.svelte';
	import {
		setAppStores,
		clearAppStores,
		setAuthStoreRef
	} from '$lib/core/di/stores-context.svelte';
	import { wireStores } from '$lib/core/di/wire-stores';
	import { AuthStore } from '$lib/features/auth/state/auth-store.svelte';
	import { setAuthStore } from '$lib/features/auth/state/auth-context.svelte';
	import { createAuthGateway } from '$lib/features/auth/data/create-auth-gateway';

	let { children } = $props();

	// Composition root: satu AuthStore untuk seluruh app.
	const auth = new AuthStore(createAuthGateway());
	setAuthStore(auth);
	setAuthStoreRef(auth);

	// 401 global dari ApiClient memicu logout terpusat.
	services.onUnauthorized = () => auth.logout();

	let booted = $state(false);

	// Store per-user + wiring, dibangun saat auth berhasil dan dilepas saat
	// logout / ganti user (keying oleh id).
	let sessionKey = $state<string | null>(null);
	let teardown: (() => void) | null = null;

	onMount(async () => {
		await auth.autoLogin();
		booted = true;
	});

	$effect(() => {
		const user = auth.isAuthenticated ? auth.user : null;
		const nextKey = user ? user.id : null;

		if (nextKey === sessionKey) return;

		// Teardown sesi lama.
		teardown?.();
		teardown = null;

		if (user) {
			const stores: AppStores = createAppStores();
			setAppStores(stores);
			sessionKey = user.id;
			teardown = wireStores(stores);
			stores.simulation.startLoop({
				userId: user.id,
				initialGameTime: user.gameCurrentTime,
				initialCash: 0,
				initialOperationalStatus: user.operationalStatus,
				initialConsecutiveNegativeDays: user.consecutiveNegativeDays,
				initialRecoveryStreakDays: user.recoveryStreakDays
			});
		} else {
			sessionKey = null;
			clearAppStores();
			services.realtimeClient.disconnect();
		}
	});

	// Halaman hanya dirender bila sesi sudah punya stores (atau kita di /login,
	// yang tak butuh stores). Mencegah anak memanggil requireAppStores() terlalu
	// awal — penyebab error "AppStores tidak tersedia".
	const onLoginPage = $derived(page.url.pathname === '/login');
	const ready = $derived(booted && (appStores.stores !== null || onLoginPage));

	// Guard: setelah boot, arahkan ke /login bila belum tersesat.
	$effect(() => {
		if (!booted) return;
		const onLogin = page.url.pathname === '/login';
		if (!auth.isAuthenticated && !onLogin) void goto('/login');
		if (auth.isAuthenticated && onLogin) void goto('/');
	});
</script>

{#if !ready}
	<div class="boot" aria-busy="true">Memuat…</div>
{:else}
	{@render children()}
{/if}

<style>
	.boot {
		display: flex;
		align-items: center;
		justify-content: center;
		min-height: 100vh;
		color: var(--color-text-secondary);
		background: var(--color-bg);
		font-family: var(--font-sans);
	}
</style>
