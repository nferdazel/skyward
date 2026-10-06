<script lang="ts">
	import CraftCard from '$lib/core/components/CraftCard.svelte';
	import TactileButton from '$lib/core/components/TactileButton.svelte';
	import AppDialogShell from '$lib/core/components/AppDialogShell.svelte';
	import { getAuthStore } from '$lib/features/auth/state/auth-context.svelte';

	const auth = getAuthStore();

	let mode = $state<'login' | 'register'>('login');
	let username = $state('');
	let password = $state('');
	let companyName = $state('');
	let ceoName = $state('');
	let submitting = $state(false);

	// Forgot-password / reset flow.
	let resetOpen = $state(false);
	let resetUsername = $state('');
	let resetPassword = $state('');
	let resetCompanyName = $state('');
	let resetCeoName = $state('');
	let resetHq = $state('');
	let resetBusy = $state(false);
	let resetMessage = $state<string | null>(null);

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

	function openReset() {
		resetUsername = username.trim();
		resetPassword = '';
		resetCompanyName = '';
		resetCeoName = '';
		resetHq = '';
		resetMessage = null;
		resetOpen = true;
	}

	async function submitReset() {
		if (!resetUsername.trim() || !resetPassword) return;
		resetBusy = true;
		const ok = await auth.resetPassword({
			username: resetUsername.trim(),
			newPassword: resetPassword,
			companyName: resetCompanyName.trim(),
			ceoName: resetCeoName.trim(),
			hqAirportIata: resetHq.trim()
		});
		resetBusy = false;
		resetMessage = ok ? 'Password reset. You can sign in now.' : (auth.error ?? 'Reset failed.');
	}
</script>

<svelte:head><title>Skyward — Sign in</title></svelte:head>

<main class="auth">
	<div class="panel">
		<h1>SKYWARD</h1>
		<p class="sub">Airline command</p>

		<CraftCard>
			<div class="tabs" role="tablist">
				<button
					role="tab"
					aria-selected={mode === 'login'}
					class:active={mode === 'login'}
					onclick={() => (mode = 'login')}>Sign in</button
				>
				<button
					role="tab"
					aria-selected={mode === 'register'}
					class:active={mode === 'register'}
					onclick={() => (mode = 'register')}>Register</button
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
						<span>Company name</span>
						<input bind:value={companyName} />
					</label>
					<label>
						<span>CEO name</span>
						<input bind:value={ceoName} />
					</label>
				{/if}

				{#if auth.error}
					<p class="error" role="alert">{auth.error}</p>
				{/if}

				{#if mode === 'login'}
					<button type="button" class="forgot" onclick={openReset}>Forgot password?</button>
				{/if}

				<div class="actions">
					<TactileButton
						text={mode === 'login' ? 'Sign in' : 'Register'}
						type="primary"
						loading={submitting}
						onclick={canSubmit ? submit : undefined}
					/>
				</div>
			</form>
		</CraftCard>
	</div>
</main>

{#if resetOpen}
	<AppDialogShell
		title="Reset password"
		subtitle="Recover with your username. Providing company and CEO helps verify ownership."
		onclose={() => (resetOpen = false)}
	>
		{#snippet children()}
			<div class="reset-form">
				<label
					><span>Username</span><input bind:value={resetUsername} autocomplete="username" /></label
				>
				<label><span>New password</span><input type="password" bind:value={resetPassword} /></label>
				<label><span>Company name</span><input bind:value={resetCompanyName} /></label>
				<label><span>CEO name</span><input bind:value={resetCeoName} /></label>
				<label><span>HQ airport (IATA)</span><input bind:value={resetHq} placeholder="SIN" /></label
				>
				{#if resetMessage}
					<p class="reset-msg" role="status">{resetMessage}</p>
				{/if}
			</div>
		{/snippet}
		{#snippet actions()}
			<TactileButton text="Close" type="secondary" onclick={() => (resetOpen = false)} />
			<TactileButton
				text="Reset password"
				type="primary"
				loading={resetBusy}
				onclick={resetUsername.trim() && resetPassword ? submitReset : undefined}
			/>
		{/snippet}
	</AppDialogShell>
{/if}

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
	.forgot {
		align-self: flex-start;
		background: none;
		border: none;
		color: var(--color-accent);
		font-size: 12px;
		cursor: pointer;
		padding: 0;
	}
	.forgot:hover {
		text-decoration: underline;
	}
	.reset-form {
		display: flex;
		flex-direction: column;
		gap: var(--space-sm);
	}
	.reset-form label {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		font-size: 11px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--color-text-secondary);
	}
	.reset-form input {
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		color: var(--color-text-primary);
		padding: var(--space-sm);
		font-size: 14px;
		text-transform: none;
	}
	.reset-msg {
		margin: 0;
		font-size: 13px;
		color: var(--color-success);
	}
</style>
