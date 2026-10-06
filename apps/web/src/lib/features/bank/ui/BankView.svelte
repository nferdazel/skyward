<script lang="ts">
	import AppCard from '$lib/core/components/AppCard.svelte';
	import AppButton from '$lib/core/components/AppButton.svelte';
	import AppBadge from '$lib/core/components/AppBadge.svelte';
	import AppEmptyState from '$lib/core/components/AppEmptyState.svelte';
	import AppDialogShell from '$lib/core/components/AppDialogShell.svelte';
	import type { BankStore } from '../state/bank-store.svelte';
	import type { Loan } from '../domain/loan-models';
	import {
		isActiveLoan,
		isAtRisk,
		loanStatusLabel,
		repaymentProgress
	} from '../domain/loan-models';

	type Props = { store: BankStore };
	let { store }: Props = $props();

	let dialog = $state<'loan' | 'repay' | null>(null);
	let selected = $state<Loan | null>(null);
	let busy = $state(false);

	// Form ambil pinjaman
	let principal = $state(0);
	let termWeeks = $state(52);

	// Form bayar
	let repayAmount = $state<number | ''>('');

	const num = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${num.format(Math.round(n))}`;
	const pct = (n: number) => `${Math.round(n * 100)}%`;

	function openLoan() {
		principal = store.state.credit?.minLoanAmount ?? 0;
		termWeeks = 52;
		dialog = 'loan';
	}

	async function submitLoan() {
		busy = true;
		await store.takeLoan({ principal, termWeeks });
		busy = false;
		dialog = null;
	}

	function openRepay(loan: Loan) {
		selected = loan;
		repayAmount = '';
		dialog = 'repay';
	}

	async function submitRepay() {
		if (!selected) return;
		busy = true;
		await store.repay(selected.id, repayAmount === '' ? null : Number(repayAmount));
		busy = false;
		dialog = null;
	}

	async function refinance(loan: Loan) {
		await store.refinance(loan.id);
	}

	const credit = $derived(store.state.credit);
</script>

<section>
	<div class="head">
		<h2>Bank</h2>
		<AppButton text="Take loan" onclick={openLoan} />
	</div>

	{#if store.state.error}
		<p class="error" role="alert">{store.state.error}</p>
	{/if}

	<div class="grid">
		<AppCard>
			<h3>Cash & accounts</h3>
			<dl>
				<div>
					<dt>Operating account</dt>
					<dd>{money(store.operatingAccount?.balance ?? 0)}</dd>
				</div>
				<div>
					<dt>Accounts</dt>
					<dd>{store.state.accounts.length}</dd>
				</div>
			</dl>
		</AppCard>

		<AppCard>
			<h3>Credit</h3>
			{#if credit}
				<dl>
					<div>
						<dt>Score</dt>
						<dd>{credit.currentScore}</dd>
					</div>
					<div>
						<dt>Tier</dt>
						<dd>{credit.creditTier}</dd>
					</div>
					<div>
						<dt>Max unsecured</dt>
						<dd>{money(credit.maxUnsecuredLoan)}</dd>
					</div>
					<div>
						<dt>Unsecured rate</dt>
						<dd>{pct(credit.unsecuredInterestRate)}</dd>
					</div>
					<div>
						<dt>Max active loans</dt>
						<dd>{credit.maxActiveLoans}</dd>
					</div>
				</dl>
				{#if credit.suggestions.length > 0}
					<ul class="suggestions">
						{#each credit.suggestions as s, i (i)}
							<li>{s}</li>
						{/each}
					</ul>
				{/if}
			{:else}
				<p class="muted">Credit report not loaded.</p>
			{/if}
		</AppCard>
	</div>

	<AppCard>
		<h3>Loans</h3>
		{#if store.state.loans.length === 0}
			<AppEmptyState title="No loans" description="No active loans." />
		{:else}
			<div class="table-wrap">
				<table>
					<thead>
						<tr>
							<th>Type</th>
							<th>Principal</th>
							<th>Remaining</th>
							<th>Rate</th>
							<th>Progress</th>
							<th>Status</th>
							<th>Actions</th>
						</tr>
					</thead>
					<tbody>
						{#each store.state.loans as l (l.id)}
							<tr>
								<td>{l.loanType}</td>
								<td>{money(l.principal)}</td>
								<td>{money(l.remainingBalance)}</td>
								<td>{pct(l.interestRate)}</td>
								<td>{pct(repaymentProgress(l))}</td>
								<td>
									<AppBadge
										label={loanStatusLabel(l)}
										tone={isAtRisk(l) ? 'error' : l.status === 'active' ? 'success' : 'secondary'}
									/>
								</td>
								<td class="actions">
									{#if isActiveLoan(l)}
										<AppButton text="Repay" variant="secondary" onclick={() => openRepay(l)} />
										<AppButton text="Refinance" variant="secondary" onclick={() => refinance(l)} />
									{/if}
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>
		{/if}
	</AppCard>
</section>

{#if dialog === 'loan' && credit}
	{@const c = credit}
	<AppDialogShell title="Take loan" onclose={() => (dialog = null)}>
		{#snippet children()}
			<label><span>Principal</span><input type="number" bind:value={principal} /></label>
			<label><span>Term (weeks)</span><input type="number" bind:value={termWeeks} /></label>
			<p class="sub">
				Min {money(c.minLoanAmount)} · maks tanpa jaminan {money(c.maxUnsecuredLoan)} · bunga {pct(
					c.unsecuredInterestRate
				)}
			</p>
		{/snippet}
		{#snippet actions()}
			<AppButton text="Cancel" variant="secondary" onclick={() => (dialog = null)} />
			<AppButton text="Take loan" loading={busy} onclick={principal > 0 ? submitLoan : undefined} />
		{/snippet}
	</AppDialogShell>
{/if}

{#if dialog === 'repay' && selected}
	{@const l = selected}
	<AppDialogShell
		title="Repay loan"
		subtitle="Remaining {money(l.remainingBalance)}"
		onclose={() => (dialog = null)}
	>
		{#snippet children()}
			<label>
				<span>Amount (blank = pay off)</span>
				<input type="number" bind:value={repayAmount} />
			</label>
		{/snippet}
		{#snippet actions()}
			<AppButton text="Cancel" variant="secondary" onclick={() => (dialog = null)} />
			<AppButton text="Repay" loading={busy} onclick={submitRepay} />
		{/snippet}
	</AppDialogShell>
{/if}

<style>
	.head {
		display: flex;
		align-items: center;
		justify-content: space-between;
		margin-bottom: var(--space-md);
	}
	h2 {
		margin: 0;
		font-size: 16px;
		letter-spacing: 0.06em;
		text-transform: uppercase;
	}
	h3 {
		margin: 0 0 var(--space-sm);
		font-size: 13px;
		letter-spacing: 0.06em;
		text-transform: uppercase;
		color: var(--color-text-secondary);
	}
	.grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
		gap: var(--space-md);
		margin-bottom: var(--space-md);
	}
	.table-wrap {
		overflow-x: auto;
	}
	table {
		width: 100%;
		border-collapse: collapse;
		font-size: 13px;
	}
	th {
		text-align: left;
		padding: var(--space-sm);
		color: var(--color-text-secondary);
		font-size: 11px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		border-bottom: 0.5px solid var(--color-border);
	}
	td {
		padding: var(--space-sm);
		border-bottom: 0.5px solid var(--color-border-subtle);
	}
	.actions {
		display: flex;
		gap: var(--space-xs);
	}
	dl {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin: 0;
	}
	dl > div {
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
	.suggestions {
		margin: var(--space-sm) 0 0;
		padding-left: var(--space-lg);
		color: var(--color-text-secondary);
		font-size: 12px;
	}
	.muted {
		color: var(--color-text-muted);
		font-size: 12px;
	}
	.error {
		color: var(--color-error);
		font-size: 13px;
	}
	label {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin-bottom: var(--space-sm);
		font-size: 11px;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--color-text-secondary);
	}
	input {
		background: var(--color-surface-2);
		border: 1px solid var(--color-border);
		border-radius: var(--radius-default);
		color: var(--color-text-primary);
		padding: var(--space-sm);
		font-size: 14px;
	}
	.sub {
		color: var(--color-text-secondary);
		font-size: 13px;
	}
</style>
