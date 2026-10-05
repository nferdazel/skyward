import { describe, expect, it, vi } from 'vitest';
import { BankStore } from './bank-store.svelte';
import type { BankGateway } from '../data/bank-gateway';
import { bankAccountFromMap } from '../domain/bank-models';
import {
	creditReportFromMap,
	loanFromMap,
	repaymentProgress,
	isAtRisk,
	isAircraftFinancing
} from '../domain/loan-models';

function makeGateway(over: Partial<BankGateway> = {}): BankGateway {
	return {
		getLoans: vi.fn().mockResolvedValue([]),
		takeLoan: vi.fn().mockResolvedValue(undefined),
		getCreditReport: vi.fn().mockResolvedValue(creditReportFromMap({})),
		getCreditHistory: vi.fn().mockResolvedValue([]),
		getAircraftFinancing: vi.fn().mockResolvedValue([]),
		financeAircraft: vi.fn().mockResolvedValue(undefined),
		refinanceLoan: vi.fn().mockResolvedValue({ success: true }),
		repayLoan: vi.fn().mockResolvedValue({ success: true }),
		getBankAccounts: vi.fn().mockResolvedValue([]),
		getBankTransactions: vi.fn().mockResolvedValue([]),
		...over
	} as unknown as BankGateway;
}

describe('bank domain helpers', () => {
	it('parses a loan and its derived labels', () => {
		const loan = loanFromMap({
			id: 'l1',
			principal: 1000,
			interest_rate: 0.1,
			remaining_balance: 500,
			status: 'active',
			missed_payments: 3,
			loan_type: 'aircraft_financing'
		});
		expect(loan.principal).toBe(1000);
		expect(isAtRisk(loan)).toBe(true);
		expect(isAircraftFinancing(loan)).toBe(true);
		// progress = 1 - 500/(1000*1.1) = 0.5454...
		expect(repaymentProgress(loan)).toBeCloseTo(1 - 500 / 1100);
	});

	it('reads a nested credit_score object as a fallback', () => {
		const r = creditReportFromMap({ credit_score: { score: 720, fleet_health: 80 }, tier: 'Gold' });
		expect(r.currentScore).toBe(720);
		expect(r.fleetHealth).toBe(80);
		expect(r.creditTier).toBe('Gold');
	});

	it('falls back to safe defaults for an empty credit report', () => {
		const r = creditReportFromMap({});
		expect(r.currentScore).toBe(500);
		expect(r.maxActiveLoans).toBe(3);
		expect(r.suggestions).toEqual([]);
	});
});

describe('BankStore', () => {
	it('load fills accounts, loans and credit', async () => {
		const gateway = makeGateway({
			getBankAccounts: vi
				.fn()
				.mockResolvedValue([
					bankAccountFromMap({ id: 'b1', account_type: 'operating', balance: 100 })
				]),
			getLoans: vi.fn().mockResolvedValue([loanFromMap({ id: 'l1' })])
		});
		const store = new BankStore(gateway);

		await store.load();

		expect(store.state.accounts).toHaveLength(1);
		expect(store.operatingAccount?.balance).toBe(100);
		expect(store.state.loans).toHaveLength(1);
	});

	it('takeLoan refetches afterwards', async () => {
		const getLoans = vi.fn().mockResolvedValue([]);
		const takeLoan = vi.fn().mockResolvedValue(undefined);
		const store = new BankStore(makeGateway({ getLoans, takeLoan }));

		const ok = await store.takeLoan({ principal: 5000, termWeeks: 52 });

		expect(ok).toBe(true);
		expect(takeLoan).toHaveBeenCalledWith({ principal: 5000, termWeeks: 52 });
		expect(getLoans).toHaveBeenCalledOnce();
	});

	it('sets error and returns false when repay fails', async () => {
		const store = new BankStore(
			makeGateway({ repayLoan: vi.fn().mockRejectedValue(new Error('no funds')) })
		);

		const ok = await store.repay('l1', 100);

		expect(ok).toBe(false);
		expect(store.state.error).toBe('no funds');
	});
});
