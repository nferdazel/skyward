<script lang="ts">
	import AppButton from '$lib/core/components/AppButton.svelte';
	import AppCard from '$lib/core/components/AppCard.svelte';
	import { getAuthStore } from '$lib/features/auth/state/auth-context.svelte';

	const auth = getAuthStore();

	let mode = $state<'login' | 'register'>('login');
	let username = $state('');
	let password = $state('');
	let companyName = $state('');
	let ceoName = $state('');
	let submitting = $state(false);

	const canSubmit = $derived(
		username.trim().length > 0 &&
			password.length > 0 &&
			(mode === 'login' || (companyName.trim() && ceoName.trim()))
	);

	async function submit() {
		if (!canSubmit || submitting) return;
		submitting = true;
		if (mode === 'login') {
			await auth.login(username.trim(), password);
		} else {
			await auth.register({
				username: username.trim(),
				password,
				companyName: companyName.trim(),
				ceoName: ceoName.trim()
			});
		}
		submitting = false;
	}
</script>

<svelte:head><title>Skyward — Masuk</title></svelte:head>

<main class="auth">
	<div class="panel">
		<h1>SKYWARD</h1>
		<p class="sub">Airline command</p>

		<AppCard>
			<div class="tabs" role="tablist">
				<button
					role="tab"
					aria-selected={mode === 'login'}
					class:active={mode === 'login'}
					onclick={() => (mode = 'login')}>Masuk</button
				>
				<button
					role="tab"
					aria-selected={mode === 'register'}
					class:active={mode === 'register'}
					onclick={() => (mode = 'register')}>Daftar</button
				>
			</div>

			<form onsubmit={(e) => (e.preventDefault(), submit())}>
				<label>
					<span>Username</span>
					<input bind:value={username} autocomplete="username" />
				</label>
				<label>
					<span>Password</span>
					<input type="password" bind:value={password} autocomplete="current-password" />
				</label>
				{#if mode === 'register'}
					<label>
						<span>Nama maskapai</span>
						<input bind:value={companyName} />
					</label>
					<label>
						<span>Nama CEO</span>
						<input bind:value={ceoName} />
					</label>
				{/if}

				{#if auth.error}
					<p class="error" role="alert">{auth.error}</p>
				{/if}

				<div class="actions">
					<AppButton
						text={mode === 'login' ? 'Masuk' : 'Daftar'}
						type="submit"
						loading={submitting}
						onclick={canSubmit ? submit : undefined}
					/>
				</div>
			</form>
		</AppCard>
	</div>
</main>

<style>
	.auth {
		min-height: 100vh;
		display: grid;
		place-items: center;
		background: var(--color-bg);
		padding: var(--space-lg);
	}
	.panel {
		width: 100%;
		max-width: 360px;
	}
	h1 {
		font-size: 20px;
		letter-spacing: 0.3em;
		margin: 0;
		color: var(--color-accent);
	}
	.sub {
		margin: 0 0 var(--space-lg);
		color: var(--color-text-muted);
		font-size: 12px;
		letter-spacing: 0.1em;
		text-transform: uppercase;
	}
	.tabs {
		display: flex;
		gap: var(--space-sm);
		margin-bottom: var(--space-md);
	}
	.tabs button {
		flex: 1;
		background: transparent;
		border: none;
		border-bottom: 2px solid transparent;
		color: var(--color-text-secondary);
		padding: var(--space-sm);
		cursor: pointer;
		font-family: var(--font-sans);
		font-weight: 600;
	}
	.tabs button.active {
		color: var(--color-accent);
		border-bottom-color: var(--color-accent);
	}
	form {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
	}
	label {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		font-size: 11px;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--color-text-secondary);
	}
	input {
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		color: var(--color-text-primary);
		padding: var(--space-sm) var(--space-md);
		font-size: 14px;
		font-family: var(--font-sans);
	}
	input:focus-visible {
		outline: 2px solid var(--color-border-focus);
		outline-offset: 1px;
	}
	.error {
		color: var(--color-error);
		font-size: 13px;
		margin: 0;
	}
	.actions {
		display: flex;
		justify-content: flex-end;
	}
</style>
