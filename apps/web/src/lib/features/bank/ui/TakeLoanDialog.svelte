<script lang="ts">
	import AppDialogShell from '$lib/core/components/AppDialogShell.svelte';
	import TactileButton from '$lib/core/components/TactileButton.svelte';
	import type { BankStore } from '../state/bank-store.svelte';
	import type { CreditReport } from '../domain/loan-models';

	/**
	 * Take-loan dialog. Ported from Flutter `TakeLoanDialog`: principal slider,
	 * term selector, computed weekly payment from the credit report rate.
	 */
	type Props = {
		store: BankStore;
		credit: CreditReport | null;
		onclose: () => void;
	};
	let { store, credit, onclose }: Props = $props();

	const terms = [12, 26, 52];
	const fallbackRate = 0.12;

	const minLoan = $derived(credit?.minLoanAmount ?? 100_000);
	const maxLoan = $derived(Math.max(minLoan, credit?.maxUnsecuredLoan ?? 5_000_000));
	const interestRate = $derived(credit?.unsecuredInterestRate ?? fallbackRate);

	let principal = $state(1_000_000);
	let termWeeks = $state(52);
	let busy = $state(false);

	const effectivePrincipal = $derived(Math.min(Math.max(principal, minLoan), maxLoan));
	const totalRepayable = $derived(effectivePrincipal * (1 + interestRate));
	const weeklyPayment = $derived(totalRepayable / termWeeks);

	const fmt = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${fmt.format(Math.round(n))}`;

	async function submit() {
		busy = true;
		await store.takeLoan({ principal: effectivePrincipal, termWeeks, loanType: 'unsecured' });
		busy = false;
		onclose();
	}
</script>

<AppDialogShell
	title="Take loan"
	subtitle="Borrow capital at {(interestRate * 100).toFixed(
		1
	)}% simple interest, auto-deducted weekly."
	{onclose}
>
	{#snippet children()}
		<div class="form">
			<label class="field">
				<span class="k">Principal amount</span>
				<input type="number" min={minLoan} max={maxLoan} bind:value={principal} />
			</label>
			<input class="slider" type="range" min={minLoan} max={maxLoan} bind:value={principal} />
			<p class="range">{money(minLoan)} – {money(maxLoan)}</p>

			<div class="field">
				<span class="k">Loan term</span>
				<div class="terms">
					{#each terms as t (t)}
						<button class:active={termWeeks === t} onclick={() => (termWeeks = t)}>{t} weeks</button
						>
					{/each}
				</div>
			</div>

			<dl class="terms-summary">
				<div>
					<dt>Principal</dt>
					<dd class="tnum">{money(effectivePrincipal)}</dd>
				</div>
				<div>
					<dt>Total repayable</dt>
					<dd class="tnum">{money(totalRepayable)}</dd>
				</div>
				<div>
					<dt>Weekly payment</dt>
					<dd class="tnum warn">{money(weeklyPayment)}</dd>
				</div>
			</dl>
		</div>
	{/snippet}
	{#snippet actions()}
		<TactileButton text="Cancel" type="secondary" onclick={onclose} />
		<TactileButton text="Take loan" type="primary" loading={busy} onclick={submit} />
	{/snippet}
</AppDialogShell>

<style>
	.form {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
	}
	.field {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
	}
	.k {
		font-size: 11px;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		color: var(--color-text-secondary);
	}
	input[type='number'] {
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		color: var(--color-text-primary);
		padding: var(--space-sm);
		font-size: 14px;
	}
	.slider {
		accent-color: var(--color-accent);
		width: 100%;
	}
	.range {
		margin: 0;
		font-size: 12px;
		color: var(--color-text-muted);
	}
	.terms {
		display: flex;
		gap: var(--space-sm);
	}
	.terms button {
		flex: 1;
		padding: var(--space-sm);
		background: var(--color-surface);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		color: var(--color-text-secondary);
		cursor: pointer;
		font-weight: 600;
		font-size: 12px;
	}
	.terms button.active {
		background: var(--color-accent-subtle);
		border-color: var(--color-accent);
		color: var(--color-accent);
	}
	.terms-summary {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin: 0;
	}
	.terms-summary > div {
		display: flex;
		justify-content: space-between;
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
	.warn {
		color: var(--color-warning);
	}
</style>
