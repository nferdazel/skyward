import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import BankView from './BankView.svelte';
import type { BankStore } from '../state/bank-store.svelte';
import { loanFromMap, creditReportFromMap } from '../domain/loan-models';
import { bankAccountFromMap } from '../domain/bank-models';

function makeStore(over: Partial<BankStore['state']> = {}): BankStore {
	const accounts = [bankAccountFromMap({ id: 'b1', account_type: 'operating', balance: 12345 })];
	const store = {
		state: {
			loading: false,
			accounts,
			transactions: [],
			loans: [
				loanFromMap({
					id: 'l1',
					principal: 100000,
					remaining_balance: 40000,
					interest_rate: 0.12,
					status: 'active',
					loan_type: 'unsecured'
				})
			],
			credit: creditReportFromMap({ current_score: 720, credit_tier: 'Gold' }),
			creditHistory: [],
			error: null,
			...over
		},
		get operatingAccount() {
			return (over.accounts ?? accounts).find((a) => a.accountType === 'operating') ?? null;
		},
		load: vi.fn(),
		refresh: vi.fn(),
		takeLoan: vi.fn(),
		repay: vi.fn(),
		refinance: vi.fn(),
		financeAircraft: vi.fn()
	};
	return store as unknown as BankStore;
}

describe('BankView', () => {
	it('shows the operating balance, credit tier and a loan row', () => {
		render(BankView, { props: { store: makeStore() } });
		expect(screen.getByText('$12,345')).toBeInTheDocument();
		expect(screen.getByText('Gold')).toBeInTheDocument();
		expect(screen.getByText('$100,000')).toBeInTheDocument();
		expect(screen.getByRole('button', { name: 'Bayar' })).toBeInTheDocument();
	});

	it('shows an empty state when there are no loans', () => {
		render(BankView, { props: { store: makeStore({ loans: [] }) } });
		expect(screen.getByText('Tidak ada pinjaman')).toBeInTheDocument();
	});
});
