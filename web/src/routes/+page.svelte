<script lang="ts">
	import AppButton from '$lib/core/components/AppButton.svelte';
	import AppCard from '$lib/core/components/AppCard.svelte';
	import { getAuthStore } from '$lib/features/auth/state/auth-context.svelte';

	const auth = getAuthStore();
</script>

<svelte:head><title>Skyward — Dashboard</title></svelte:head>

<main class="shell">
	<header>
		<span class="brand">SKYWARD</span>
		{#if auth.user}
			<span class="who">{auth.user.companyName || auth.user.username}</span>
		{/if}
		<AppButton text="Keluar" variant="secondary" onclick={() => auth.logout()} />
	</header>

	<section>
		<AppCard>
			<h2>Selamat datang, {auth.user?.ceoName || auth.user?.username}</h2>
			<p>
				Shell dashboard belum diisi. Fitur (armada, rute, keuangan, bank, dsb.) menyusul sesuai
				backlog.
			</p>
			<dl>
				<div>
					<dt>HQ</dt>
					<dd>{auth.user?.hqAirportIata}</dd>
				</div>
				<div>
					<dt>Status</dt>
					<dd>{auth.user?.operationalStatus}</dd>
				</div>
				<div>
					<dt>Net worth</dt>
					<dd>{auth.user?.netWorth}</dd>
				</div>
			</dl>
		</AppCard>
	</section>
</main>

<style>
	.shell {
		min-height: 100vh;
		background: var(--color-bg);
		padding: var(--space-lg);
	}
	header {
		display: flex;
		align-items: center;
		gap: var(--space-md);
		padding-bottom: var(--space-lg);
	}
	.brand {
		color: var(--color-accent);
		font-weight: 700;
		letter-spacing: 0.3em;
	}
	.who {
		margin-left: auto;
		color: var(--color-text-secondary);
		font-size: 13px;
	}
	h2 {
		margin: 0 0 var(--space-sm);
		font-size: 16px;
	}
	p {
		color: var(--color-text-secondary);
		font-size: 13px;
	}
	dl {
		display: flex;
		gap: var(--space-xl);
		margin: var(--space-md) 0 0;
	}
	dt {
		color: var(--color-text-muted);
		font-size: 11px;
		text-transform: uppercase;
		letter-spacing: 0.08em;
	}
	dd {
		margin: 0;
		font-size: 14px;
	}
</style>
