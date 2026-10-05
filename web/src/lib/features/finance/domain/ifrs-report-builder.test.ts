import { describe, expect, it } from 'vitest';
import {
	bankTransactionFromMap,
	type BankTransaction
} from '$lib/features/bank/domain/bank-models';
import {
	buildIncomeStatement,
	buildBalanceSheet,
	buildCashFlows,
	isBalanced
} from './ifrs-report-builder';
import { groupFor, isOperationsExpense, isLeaseExpense } from './ifrs-category';
import { financeSnapshotFromMap } from './finance-snapshot';

function txn(over: Record<string, unknown>): BankTransaction {
	return bankTransactionFromMap(over);
}

describe('ifrs-category', () => {
	it('groups a known key to its display group', () => {
		expect(groupFor('ticket_revenue')).toBe('ticketSales');
		expect(groupFor('fuel')).toBe('operations');
		expect(groupFor('aircraft_lease_deposit')).toBe('lease');
		expect(groupFor('loan_repayment')).toBe('financing');
		expect(groupFor('unknown_key')).toBe('other');
	});

	it('cogs/opex count as operations and lease buckets may overlap', () => {
		expect(isOperationsExpense('opex', 'aircraft_lease')).toBe(true);
		expect(isLeaseExpense('opex', 'aircraft_lease')).toBe(true);
	});
});

describe('buildIncomeStatement', () => {
	it('sums revenue and cost lines from transactions', () => {
		const statement = buildIncomeStatement([
			txn({ transaction_type: 'credit', ifrs_subcategory: 'ticket_revenue', amount: 1000 }),
			txn({ transaction_type: 'credit', ifrs_subcategory: 'cargo_revenue', amount: 200 }),
			txn({ transaction_type: 'debit', ifrs_subcategory: 'fuel', amount: 300 }),
			txn({ transaction_type: 'debit', ifrs_subcategory: 'crew', amount: 150 }),
			txn({ transaction_type: 'debit', ifrs_subcategory: 'aircraft_lease', amount: 50 })
		]);

		expect(statement.ticketSales).toBe(1000);
		expect(statement.cargoRevenue).toBe(200);
		expect(statement.totalRevenue).toBe(1200);
		expect(statement.fuel).toBe(300);
		expect(statement.crew).toBe(150);
		expect(statement.fleetLeasing).toBe(50);
		expect(statement.totalOperatingCosts).toBe(500);
		expect(statement.netIncome).toBe(700);
	});

	it('treats an empty-subcategory cogs debit as fuel (legacy rows)', () => {
		const statement = buildIncomeStatement([
			txn({ transaction_type: 'debit', ifrs_category: 'cogs', ifrs_subcategory: '', amount: 42 })
		]);
		expect(statement.fuel).toBe(42);
	});
});

describe('buildCashFlows', () => {
	it('buckets operating, investing and financing, and nets them', () => {
		const flows = buildCashFlows([
			txn({
				transaction_type: 'credit',
				ifrs_category: 'revenue',
				ifrs_subcategory: 'ticket_revenue',
				amount: 1000
			}),
			txn({ transaction_type: 'debit', ifrs_subcategory: 'fuel', amount: 400 }),
			txn({ transaction_type: 'debit', ifrs_subcategory: 'aircraft_purchase', amount: 5000 }),
			txn({ transaction_type: 'credit', ifrs_subcategory: 'aircraft_sale', amount: 2000 }),
			txn({ transaction_type: 'credit', ifrs_subcategory: 'loan_disbursement', amount: 3000 }),
			txn({ transaction_type: 'debit', ifrs_subcategory: 'loan_repayment', amount: 1000 })
		]);

		expect(flows.operatingCashFlow).toBe(600);
		expect(flows.investingCashFlow).toBe(-3000);
		expect(flows.financingCashFlow).toBe(2000);
		expect(flows.netCashChange).toBe(600 - 3000 + 2000);
	});

	it('counts a lease deposit as capital expenditure (not operating)', () => {
		const flows = buildCashFlows([
			txn({ transaction_type: 'debit', ifrs_subcategory: 'aircraft_lease_deposit', amount: 900 })
		]);
		expect(flows.capitalExpenditure).toBe(900);
		expect(flows.operatingOutflows).toBe(0);
	});
});

describe('buildBalanceSheet', () => {
	it('always balances via residual equity', () => {
		const snapshot = financeSnapshotFromMap({ cash: 1000, owned_aircraft_asset_value: 4000 });
		const sheet = buildBalanceSheet(snapshot, 1500);
		expect(sheet.totalAssets).toBe(5000);
		expect(sheet.totalLiabilities).toBe(1500);
		expect(sheet.totalEquity).toBe(3500);
		expect(isBalanced(sheet)).toBe(true);
	});
});
