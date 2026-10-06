import type { FinanceSnapshot } from './finance-snapshot';
import { runwayIndicator } from '$lib/features/dashboard/domain/overview-snapshot';

/**
 * Finance overview derivation. Ported from Flutter `FinanceOverview`.
 *
 * DISPLAY aggregation only. Runway here is DIFFERENT from the dashboard on
 * purpose: this one includes debt service (weekly payment / 7) in the burn so
 * the player sees the more conservative figure. The two formulas are
 * intentionally distinct (see the Flutter doc comment).
 */
export interface FinanceOverview {
	runwayDays: number | null;
	runwayLabel: string;
	runwayColor: string;
	burnMixLabel: string;
	largestExpenseLabel: string;
	coverageLabel: string;
	coverageColor: string;
	runwayVerdict: string;
}

export interface FinanceOverviewInputs {
	snapshot: FinanceSnapshot;
	totalLease: number;
	totalOperations: number;
	totalRepair: number;
	totalPurchase: number;
	totalExpense: number;
	/** Sum of weekly payments across active loans (bank). */
	weeklyDebtPayment: number;
}

export function buildFinanceOverview(i: FinanceOverviewInputs): FinanceOverview {
	const rollingExpense = i.snapshot.rollingExpense30d;
	const rollingRevenue = i.snapshot.rollingRevenue30d;
	const dailyBurn =
		i.snapshot.ledgerWindowDays > 0 ? rollingExpense / i.snapshot.ledgerWindowDays : 0;
	const dailyDebt = i.weeklyDebtPayment > 0 ? i.weeklyDebtPayment / 7 : 0;
	const effectiveBurn = dailyBurn + dailyDebt;
	const runwayDays = effectiveBurn > 0 ? i.snapshot.cash / effectiveBurn : null;
	const runway = runwayIndicator(runwayDays);

	const largest = [
		{ label: 'Fleet Leasing', value: i.totalLease },
		{ label: 'Fuel & Landing', value: i.totalOperations },
		{ label: 'Hangar Repairs', value: i.totalRepair },
		{ label: 'Fleet Acquisition', value: i.totalPurchase }
	].sort((a, b) => b.value - a.value);
	const largestExpenseLabel = largest[0].value > 0 ? largest[0].label : '…';

	const burnMixLabel =
		i.totalExpense <= 0
			? 'No expense history'
			: `${Math.round((i.totalLease / i.totalExpense) * 100)}% lease / ${Math.round((i.totalOperations / i.totalExpense) * 100)}% ops`;

	const coverageHealthy = rollingRevenue >= rollingExpense;
	const coverageLabel = coverageHealthy
		? 'Coverage healthy'
		: rollingExpense > 0
			? 'Coverage weak'
			: 'No expense history';
	const coverageColor = coverageHealthy ? 'success' : 'warning';

	return {
		runwayDays,
		runwayLabel: runway.label,
		runwayColor: runway.color,
		burnMixLabel,
		largestExpenseLabel,
		coverageLabel,
		coverageColor,
		runwayVerdict:
			runwayDays === null
				? 'No burn data to estimate runway.'
				: `At current burn, cash lasts ${runwayDays.toFixed(0)} days.`
	};
}

/** Operating margin (%) across the ledger window. */
export function operatingMargin(totalRevenue: number, totalExpense: number): number {
	return totalRevenue > 0 ? ((totalRevenue - totalExpense) / totalRevenue) * 100 : 0;
}

/** 7d vs prior-7d net delta from the daily snapshots (newest first). Null when <14 days. */
export function weekDelta(dailyNet: number[]): number | null {
	if (dailyNet.length < 14) return null;
	const recent = dailyNet.slice(0, 7).reduce((s, v) => s + v, 0);
	const prior = dailyNet.slice(7, 14).reduce((s, v) => s + v, 0);
	return recent - prior;
}
