/**
 * Pinjaman bank. Port dari Flutter `Loan`.
 *
 * Semua nilai uang otoritatif dari server. `repaymentProgress` hanyalah
 * turunan tampilan dari angka server, bukan perhitungan saldo.
 */
export interface Loan {
	id: string;
	principal: number;
	interestRate: number;
	remainingBalance: number;
	weeklyPayment: number;
	status: string;
	loanType: string;
	collateralAircraftId: string | null;
	missedPayments: number;
	originatedGameDate: string | null;
	takenAt: string | null;
}

function str(v: unknown, fallback = ''): string {
	return typeof v === 'string' ? v : fallback;
}
function num(v: unknown, fallback = 0): number {
	return typeof v === 'number' && Number.isFinite(v) ? v : fallback;
}
function dateStr(v: unknown): string | null {
	return typeof v === 'string' && v ? v : null;
}

export function loanFromMap(map: Record<string, unknown>): Loan {
	return {
		id: str(map.id),
		principal: num(map.principal),
		interestRate: num(map.interest_rate, 0.05),
		remainingBalance: num(map.remaining_balance),
		weeklyPayment: num(map.weekly_payment),
		status: str(map.status, 'active'),
		loanType: str(map.loan_type, 'unsecured'),
		collateralAircraftId:
			typeof map.collateral_aircraft_id === 'string' ? map.collateral_aircraft_id : null,
		missedPayments: num(map.missed_payments),
		originatedGameDate: dateStr(map.originated_game_date),
		takenAt: dateStr(map.taken_at)
	};
}

export const isActiveLoan = (l: Loan) => l.status === 'active';
export const isPaidOff = (l: Loan) => l.status === 'paid_off';
export const isDefaulted = (l: Loan) => l.status === 'defaulted';
export const isRepossessed = (l: Loan) => l.status === 'repossessed';
export const isAircraftFinancing = (l: Loan) => l.loanType === 'aircraft_financing';
/** Berisiko default (3+ pembayaran terlewat). */
export const isAtRisk = (l: Loan) => l.missedPayments >= 3;

export function repaymentProgress(l: Loan): number {
	if (l.principal <= 0) return 1;
	return 1 - l.remainingBalance / (l.principal * (1 + l.interestRate));
}

export function loanStatusLabel(l: Loan): string {
	switch (l.status) {
		case 'active':
			return 'Active';
		case 'paid_off':
			return 'Paid Off';
		case 'defaulted':
			return 'Defaulted';
		case 'repossessed':
			return 'Repossessed';
		default:
			return l.status;
	}
}

export function loanTypeLabel(l: Loan): string {
	switch (l.loanType) {
		case 'secured':
			return 'Secured';
		case 'credit_line':
			return 'Credit Line';
		case 'aircraft_financing':
			return 'Aircraft Financing';
		default:
			return 'Unsecured';
	}
}

/** Laporan kredit. Port dari Flutter `CreditReport`. */
export interface CreditReport {
	currentScore: number;
	fleetHealth: number;
	revenueStability: number;
	debtRatio: number;
	cashReserve: number;
	profitHistory: number;
	creditTier: string;
	maxUnsecuredLoan: number;
	maxSecuredLoan: number;
	maxFinancingAmount: number;
	baseInterestRate: number;
	unsecuredInterestRate: number;
	securedInterestRate: number;
	minLoanAmount: number;
	maxActiveLoans: number;
	suggestions: string[];
}

export function creditReportFromMap(map: Record<string, unknown>): CreditReport {
	const nested =
		map.credit_score && typeof map.credit_score === 'object'
			? (map.credit_score as Record<string, unknown>)
			: null;
	const pickNum = (a: unknown, b: unknown, fallback: number): number => {
		if (typeof a === 'number' && Number.isFinite(a)) return a;
		if (typeof b === 'number' && Number.isFinite(b)) return b;
		return fallback;
	};
	return {
		currentScore: pickNum(map.current_score, nested?.score, 500),
		fleetHealth: pickNum(map.fleet_health, nested?.fleet_health, 100),
		revenueStability: pickNum(map.revenue_stability, nested?.revenue_stability, 100),
		debtRatio: pickNum(map.debt_ratio, nested?.debt_ratio, 100),
		cashReserve: pickNum(map.cash_reserve, nested?.cash_reserve, 100),
		profitHistory: pickNum(map.profit_history, nested?.profit_history, 100),
		creditTier: str(map.credit_tier ?? map.tier, 'Standard'),
		maxUnsecuredLoan: num(map.max_unsecured_loan, 5_000_000),
		maxSecuredLoan: num(map.max_secured_loan, 20_000_000),
		maxFinancingAmount: num(map.max_financing_amount, 25_000_000),
		baseInterestRate: num(map.base_interest_rate, 0.12),
		unsecuredInterestRate: num(map.unsecured_interest_rate, num(map.base_interest_rate, 0.12)),
		securedInterestRate: num(map.secured_interest_rate, 0.1),
		minLoanAmount: num(map.min_loan_amount, 100_000),
		maxActiveLoans: num(map.max_active_loans, 3),
		suggestions: Array.isArray(map.suggestions) ? map.suggestions.map((s) => String(s)) : []
	};
}

export const isPlatinum = (r: CreditReport) => r.creditTier === 'Platinum';
export const isGoldOrAbove = (r: CreditReport) =>
	r.creditTier === 'Platinum' || r.creditTier === 'Gold';
export const isSubprime = (r: CreditReport) => r.creditTier === 'Subprime';

/** Snapshot riwayat skor kredit. Port dari Flutter `CreditScoreSnapshot`. */
export interface CreditScoreSnapshot {
	score: number;
	fleetHealth: number;
	revenueStability: number;
	debtRatio: number;
	cashReserve: number;
	profitHistory: number;
	gameDate: string;
}

export function creditScoreSnapshotFromMap(map: Record<string, unknown>): CreditScoreSnapshot {
	return {
		score: num(map.score, 500),
		fleetHealth: num(map.fleet_health_score, 100),
		revenueStability: num(map.revenue_stability_score, 100),
		debtRatio: num(map.debt_ratio_score, 100),
		cashReserve: num(map.cash_reserves_score, 100),
		profitHistory: num(map.profit_history_score, 100),
		gameDate: dateStr(map.game_date) ?? '2020-01-01'
	};
}
