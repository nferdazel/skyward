<script lang="ts">
	import '$lib/core/theme/tokens.css';
	import { onMount } from 'svelte';
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import { services, createAuthGateway } from '$lib/core/di/services';
	import { AuthStore } from '$lib/features/auth/state/auth-store.svelte';
	import { setAuthStore } from '$lib/features/auth/state/auth-context.svelte';

	let { children } = $props();

	// Composition root: satu AuthStore untuk seluruh app.
	const auth = new AuthStore(createAuthGateway());
	setAuthStore(auth);

	// 401 global dari ApiClient memicu logout terpusat.
	services.onUnauthorized = () => auth.logout();

	let booted = $state(false);

	onMount(async () => {
		await auth.autoLogin();
		booted = true;
	});

	// Guard: setelah boot, arahkan ke /login bila belum tersesat.
	$effect(() => {
		if (!booted) return;
		const onLogin = page.url.pathname === '/login';
		if (!auth.isAuthenticated && !onLogin) void goto('/login');
		if (auth.isAuthenticated && onLogin) void goto('/');
	});
</script>

{#if !booted}
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
