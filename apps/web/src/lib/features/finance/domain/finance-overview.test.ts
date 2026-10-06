import { describe, expect, it } from 'vitest';
import { buildFinanceOverview, operatingMargin, weekDelta } from './finance-overview';
import { emptyFinanceSnapshot } from './finance-snapshot';

describe('buildFinanceOverview', () => {
	it('returns null runway with no burn', () => {
		const o = buildFinanceOverview({
			snapshot: emptyFinanceSnapshot(),
			totalLease: 0,
			totalOperations: 0,
			totalRepair: 0,
			totalPurchase: 0,
			totalExpense: 0,
			weeklyDebtPayment: 0
		});
		expect(o.runwayDays).toBeNull();
		expect(o.runwayVerdict).toContain('No burn data');
	});

	it('includes weekly debt service in the burn (conservative runway)', () => {
		// cash 70d of pure ledger burn; debt service shortens runway further.
		const snapshot = {
			...emptyFinanceSnapshot(),
			cash: 3000,
			rollingExpense30d: 3000,
			ledgerWindowDays: 30
		};
		const noDebt = buildFinanceOverview({
			snapshot,
			totalLease: 3000,
			totalOperations: 0,
			totalRepair: 0,
			totalPurchase: 0,
			totalExpense: 3000,
			weeklyDebtPayment: 0
		});
		const withDebt = buildFinanceOverview({
			snapshot,
			totalLease: 3000,
			totalOperations: 0,
			totalRepair: 0,
			totalPurchase: 0,
			totalExpense: 3000,
			weeklyDebtPayment: 70
		});
		// daily burn 100 → 30 days; adding 10/day debt → 3000/110 ≈ 27.27
		expect(noDebt.runwayDays).toBeCloseTo(30, 5);
		expect(withDebt.runwayDays).toBeCloseTo(3000 / 110, 4);
		expect(withDebt.runwayDays! < noDebt.runwayDays!).toBe(true);
	});

	it('picks the largest expense bucket', () => {
		const o = buildFinanceOverview({
			snapshot: { ...emptyFinanceSnapshot(), rollingExpense30d: 100, ledgerWindowDays: 30 },
			totalLease: 10,
			totalOperations: 90,
			totalRepair: 0,
			totalPurchase: 0,
			totalExpense: 100,
			weeklyDebtPayment: 0
		});
		expect(o.largestExpenseLabel).toBe('Fuel & Landing');
	});
});

describe('operatingMargin', () => {
	it('is 0 with no revenue and computes percentage otherwise', () => {
		expect(operatingMargin(0, 100)).toBe(0);
		expect(operatingMargin(1000, 800)).toBeCloseTo(20);
	});
});

describe('weekDelta', () => {
	it('is null with fewer than 14 days and computes the delta otherwise', () => {
		expect(weekDelta([1, 2, 3])).toBeNull();
		const days = Array.from({ length: 14 }, (_, i) => (i < 7 ? 10 : 4));
		expect(weekDelta(days)).toBe(70 - 28);
	});
});
