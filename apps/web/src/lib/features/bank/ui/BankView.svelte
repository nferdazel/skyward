<script lang="ts">
	import CraftCard from '$lib/core/components/CraftCard.svelte';
	import TactileButton from '$lib/core/components/TactileButton.svelte';
	import TakeLoanDialog from './TakeLoanDialog.svelte';
	import type { BankStore } from '../state/bank-store.svelte';
	import type { Loan } from '../domain/loan-models';
	import {
		isActiveLoan,
		loanStatusLabel,
		loanTypeLabel,
		repaymentProgress
	} from '../domain/loan-models';
	import { creditTierColor, colors } from '$lib/core/theme/tokens';

	/**
	 * Bank panel. Ported from Flutter `BankPanel`: credit rating card, operating
	 * account card, active-debt strip, loan cards, collapsible history.
	 */
	type Props = { store: BankStore };
	let { store }: Props = $props();

	let loanDialog = $state(false);
	let busy = $state(false);
	let historyOpen = $state(false);

	const fmt = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 });
	const money = (n: number) => `$${fmt.format(Math.round(n))}`;

	const credit = $derived(store.state.credit);
	const loans = $derived(store.state.loans);
	const operating = $derived(store.operatingAccount);

	const activeLoans = $derived(loans.filter(isActiveLoan));
	const historicalLoans = $derived(loans.filter((l) => !isActiveLoan(l)));
	const totalOutstanding = $derived(activeLoans.reduce((s, l) => s + l.remainingBalance, 0));
	const totalWeekly = $derived(activeLoans.reduce((s, l) => s + l.weeklyPayment, 0));
	const remainingCapacity = $derived(
		credit
			? Math.max(0, Math.min(credit.maxUnsecuredLoan - totalOutstanding, credit.maxUnsecuredLoan))
			: 0
	);

	async function repayOff(loan: Loan) {
		busy = true;
		await store.repay(loan.id, null);
		busy = false;
	}
	async function refinance(loan: Loan) {
		busy = true;
		await store.refinance(loan.id);
		busy = false;
	}

	type SubScore = { label: string; value: number };
	const subScores = $derived(
		credit
			? ([
					{ label: 'Fleet Health', value: credit.fleetHealth },
					{ label: 'Revenue Stable', value: credit.revenueStability },
					{ label: 'Debt Ratio', value: credit.debtRatio },
					{ label: 'Cash Reserve', value: credit.cashReserve },
					{ label: 'Profit History', value: credit.profitHistory }
				] as SubScore[])
			: []
	);

	function barColor(score: number): string {
		if (score >= 70) return colors.success;
		if (score >= 40) return colors.warning;
		return colors.error;
	}
</script>

<div class="bank">
	<div class="head">
		<h2>Bank</h2>
		<TactileButton text="Take loan" type="primary" onclick={() => (loanDialog = true)} />
	</div>

	{#if store.state.error}
		<p class="err" role="alert">{store.state.error}</p>
	{/if}

	{#if store.state.loading && !credit && activeLoans.length === 0}
		<p class="muted" role="status" aria-live="polite">Loading bank data…</p>
	{/if}

	<div class="grid">
		{#if credit}
			{@const tierColor = creditTierColor(credit.creditTier)}
			<CraftCard>
				<div class="tier-border" style="background: {tierColor};"></div>
				<div class="card-pad">
					<div class="row-between">
						<span class="k">Credit rating</span>
						<span class="badge" style="color: {tierColor}; background: {tierColor}1f;"
							>{credit.creditTier}</span
						>
					</div>
					<span class="big" style="color: {tierColor};">{credit.currentScore}</span>
					<div class="subs">
						{#each subScores as s (s.label)}
							<div class="sub">
								<span class="sub-label">{s.label}</span>
								<span class="sub-bar"
									><span
										class="sub-fill"
										style="width: {Math.min(100, s.value)}%; background: {barColor(s.value)};"
									></span></span
								>
								<span class="sub-val tnum">{Math.round(s.value)}</span>
							</div>
						{/each}
					</div>
					{#if credit.suggestions.length > 0}
						<p class="suggestion">{credit.suggestions[0]}</p>
					{/if}
				</div>
			</CraftCard>
		{/if}

		{#if operating}
			<CraftCard>
				<div class="tier-border" style="background: {colors.success};"></div>
				<div class="card-pad">
					<span class="k">Operating account</span>
					<span class="big" style="color: {colors.success};">{money(operating.balance)}</span>
					{#if credit}
						<div class="limits">
							<span class="k">Credit limits</span>
							<div class="limit">
								<span>Unsecured</span><span class="tnum">{money(credit.maxUnsecuredLoan)}</span>
							</div>
							<div class="limit">
								<span>Secured</span><span class="tnum">{money(credit.maxSecuredLoan)}</span>
							</div>
							<div class="limit">
								<span>Financing</span><span class="tnum">{money(credit.maxFinancingAmount)}</span>
							</div>
							<div class="limit">
								<span>Rate</span><span class="warn"
									>{(credit.unsecuredInterestRate * 100).toFixed(1)}% APR</span
								>
							</div>
						</div>
					{/if}
				</div>
			</CraftCard>
		{/if}
	</div>

	{#if activeLoans.length > 0}
		<span class="section">Active debt</span>
		<CraftCard>
			<div class="debt-strip">
				<div>
					<span class="k">Outstanding</span><span class="v tnum">{money(totalOutstanding)}</span>
				</div>
				<span class="vline"></span>
				<div><span class="k">Weekly</span><span class="v tnum">{money(totalWeekly)}</span></div>
				<span class="vline"></span>
				<div>
					<span class="k">Remaining capacity</span><span class="v tnum"
						>{money(remainingCapacity)}</span
					>
				</div>
			</div>
		</CraftCard>

		<div class="loan-cards">
			{#each activeLoans as loan (loan.id)}
				{@const progress = Math.max(0, Math.min(1, repaymentProgress(loan)))}
				{@const pc =
					progress > 0.8 ? colors.success : progress > 0.4 ? colors.accent : colors.warning}
				<CraftCard>
					<div class="loan-border" style="background: {pc};"></div>
					<div class="card-pad">
						<div class="row-between">
							<span class="principal tnum">{money(loan.principal)}</span>
							<span class="badge" style="color: {colors.neutral};">{loanTypeLabel(loan)}</span>
							<span class="badge" style="color: {colors.neutral};"
								>{Math.round(loan.interestRate * 100)}% APR</span
							>
						</div>
						<div class="progress">
							<span class="progress-fill" style="width: {progress * 100}%; background: {pc};"
							></span>
						</div>
						<div class="loan-foot">
							<span class="muted"
								>{money(loan.remainingBalance)} left · {money(loan.weeklyPayment)}/wk</span
							>
							<span class="pct tnum" style="color: {pc};">{Math.round(progress * 100)}%</span>
							<TactileButton
								text="Pay off"
								type="secondary"
								height="28px"
								loading={busy}
								onclick={() => repayOff(loan)}
							/>
							<TactileButton
								text="Refinance"
								type="ghost"
								height="28px"
								loading={busy}
								onclick={() => refinance(loan)}
							/>
						</div>
					</div>
				</CraftCard>
			{/each}
		</div>
	{/if}

	{#if historicalLoans.length > 0}
		<button class="history-toggle" onclick={() => (historyOpen = !historyOpen)}>
			{historyOpen ? '▾' : '▸'} Loan history ({historicalLoans.length})
		</button>
		{#if historyOpen}
			<div class="history">
				{#each historicalLoans as loan (loan.id)}
					<div class="hist-row">
						<span class="hist-amount tnum">{money(loan.principal)}</span>
						<span
							class="badge"
							style="color: {loanStatusLabel(loan) === 'Paid Off' ? colors.success : colors.error};"
						>
							{loanStatusLabel(loan)}
						</span>
					</div>
				{/each}
			</div>
		{/if}
	{/if}
</div>

{#if loanDialog}
	<TakeLoanDialog {store} {credit} onclose={() => (loanDialog = false)} />
{/if}

<style>
	.bank {
		display: flex;
		flex-direction: column;
		gap: var(--space-md);
	}
	.head {
		display: flex;
		align-items: center;
		justify-content: space-between;
	}
	h2 {
		margin: 0;
		font-size: 16px;
		letter-spacing: 0.06em;
		text-transform: uppercase;
	}
	.section {
		font-size: 11px;
		font-weight: 600;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		color: var(--color-text-muted);
	}
	.grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
		gap: var(--space-md);
	}
	.grid :global(.craft) {
		position: relative;
		padding: 0;
		overflow: hidden;
	}
	.tier-border,
	.loan-border {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		height: 2px;
	}
	.loan-border {
		top: 0;
		bottom: 0;
		right: auto;
		width: 3px;
		height: auto;
	}
	.card-pad {
		padding: var(--space-lg);
		display: flex;
		flex-direction: column;
		gap: var(--space-sm);
	}
	.row-between {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
	}
	.row-between .badge:first-of-type {
		margin-left: 0;
	}
	.k {
		font-size: 10px;
		letter-spacing: 0.08em;
		text-transform: uppercase;
		color: var(--color-text-muted);
	}
	.big {
		font-size: 26px;
		font-weight: 700;
		font-variant-numeric: tabular-nums;
		line-height: 1.1;
	}
	.badge {
		font-size: 10px;
		font-weight: 600;
		padding: 1px 6px;
		border-radius: var(--radius-default);
		border: 1px solid currentColor;
	}
	.subs {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin-top: var(--space-sm);
	}
	.sub {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
	}
	.sub-label {
		flex: 1;
		font-size: 11px;
		color: var(--color-text-secondary);
	}
	.sub-bar {
		width: 70px;
		height: 4px;
		background: var(--color-border);
		border-radius: 2px;
		overflow: hidden;
	}
	.sub-fill {
		display: block;
		height: 100%;
	}
	.sub-val {
		width: 32px;
		text-align: right;
		font-size: 11px;
		color: var(--color-text-secondary);
	}
	.suggestion {
		margin: var(--space-sm) 0 0;
		font-size: 12px;
		color: var(--color-text-muted);
	}
	.limits {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
		margin-top: var(--space-sm);
	}
	.limit {
		display: flex;
		justify-content: space-between;
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.warn {
		color: var(--color-warning);
	}
	.debt-strip {
		display: flex;
		align-items: center;
		gap: var(--space-lg);
	}
	.debt-strip > div {
		flex: 1;
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
	}
	.v {
		font-size: 16px;
		font-weight: 700;
	}
	.vline {
		width: 1px;
		height: 28px;
		background: var(--color-border);
	}
	.loan-cards {
		display: flex;
		flex-direction: column;
		gap: var(--space-sm);
	}
	.loan-cards :global(.craft) {
		position: relative;
		padding: 0;
		overflow: hidden;
	}
	.principal {
		font-size: 15px;
		font-weight: 700;
		margin-right: var(--space-xs);
	}
	.progress {
		height: 4px;
		background: var(--color-border);
		border-radius: 2px;
		overflow: hidden;
	}
	.progress-fill {
		display: block;
		height: 100%;
	}
	.loan-foot {
		display: flex;
		align-items: center;
		gap: var(--space-sm);
	}
	.loan-foot .muted {
		flex: 1;
	}
	.pct {
		font-weight: 700;
		font-size: 12px;
	}
	.muted {
		font-size: 12px;
		color: var(--color-text-secondary);
	}
	.history-toggle {
		align-self: flex-start;
		background: none;
		border: none;
		color: var(--color-text-secondary);
		font-size: 12px;
		cursor: pointer;
		padding: var(--space-xs) 0;
	}
	.history {
		display: flex;
		flex-direction: column;
		gap: var(--space-xs);
	}
	.hist-row {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: var(--space-xs) 0;
		border-bottom: 1px solid var(--color-border-subtle);
	}
	.hist-amount {
		color: var(--color-text-muted);
		text-decoration: line-through;
	}
	.err {
		color: var(--color-error);
		font-size: 13px;
	}
</style>
