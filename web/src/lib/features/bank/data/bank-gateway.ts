import { ApiError } from '$lib/core/api/errors';
import type { ApiClient } from '$lib/core/api/api-client';
import {
	bankAccountFromMap,
	bankTransactionFromMap,
	type BankAccount,
	type BankTransaction
} from '../domain/bank-models';
import {
	creditReportFromMap,
	creditScoreSnapshotFromMap,
	loanFromMap,
	type CreditReport,
	type CreditScoreSnapshot,
	type Loan
} from '../domain/loan-models';

export class BankGatewayError extends Error {
	readonly operation: string;
	constructor(message: string, operation: string) {
		super(message);
		this.name = 'BankGatewayError';
		this.operation = operation;
	}
}

function wrap(err: unknown, operation: string): BankGatewayError {
	if (err instanceof ApiError) return new BankGatewayError(err.message, operation);
	return new BankGatewayError(err instanceof Error ? err.message : String(err), operation);
}

function rows(v: unknown): Record<string, unknown>[] {
	return Array.isArray(v)
		? v.filter((m): m is Record<string, unknown> => !!m && typeof m === 'object')
		: [];
}

export type LoanType = 'unsecured' | 'secured' | 'credit_line';

/** Operasi bank via skyward-api (Go REST). Port dari `GoBankGateway`. */
export class BankGateway {
	constructor(private readonly api: ApiClient) {}

	async getLoans(): Promise<Loan[]> {
		try {
			return rows(await this.api.get<unknown>('/bank/loans')).map(loanFromMap);
		} catch (err) {
			throw wrap(err, 'getLoans');
		}
	}

	async takeLoan(input: {
		principal: number;
		termWeeks: number;
		loanType?: LoanType;
		collateralAircraftId?: string | null;
	}): Promise<void> {
		const body: Record<string, unknown> = {
			principal: input.principal,
			term_weeks: input.termWeeks,
			loan_type: input.loanType ?? 'unsecured'
		};
		// Dart `?collateralAircraftId` membuang key bila null — samakan.
		if (input.collateralAircraftId) body.collateral_aircraft_id = input.collateralAircraftId;
		try {
			await this.api.post('/bank/loans', body);
		} catch (err) {
			throw wrap(err, 'takeLoan');
		}
	}

	async getCreditReport(): Promise<CreditReport> {
		try {
			const res = await this.api.get<Record<string, unknown>>('/bank/credit');
			return creditReportFromMap(res ?? {});
		} catch (err) {
			throw wrap(err, 'getCreditReport');
		}
	}

	async getCreditHistory(): Promise<CreditScoreSnapshot[]> {
		try {
			return rows(await this.api.get<unknown>('/bank/credit/history')).map(
				creditScoreSnapshotFromMap
			);
		} catch (err) {
			throw wrap(err, 'getCreditHistory');
		}
	}

	/** Pinjaman bertipe aircraft_financing, disaring dari daftar pinjaman. */
	async getAircraftFinancing(): Promise<Loan[]> {
		const loans = await this.getLoans();
		return loans.filter((l) => l.loanType === 'aircraft_financing');
	}

	async financeAircraft(input: {
		aircraftModelId: string;
		downPaymentPct: number;
		termMonths: number;
	}): Promise<void> {
		try {
			await this.api.post('/bank/finance-aircraft', {
				aircraft_model_id: input.aircraftModelId,
				down_payment_pct: input.downPaymentPct,
				term_months: input.termMonths
			});
		} catch (err) {
			throw wrap(err, 'financeAircraft');
		}
	}

	async refinanceLoan(loanId: string): Promise<Record<string, unknown>> {
		try {
			const res = await this.api.post<Record<string, unknown>>(`/bank/loans/${loanId}/refinance`);
			return res ?? { success: true };
		} catch (err) {
			throw wrap(err, 'refinanceLoan');
		}
	}

	/** `amount` null = bayar lunas (server menentukan jumlahnya). */
	async repayLoan(loanId: string, amount: number | null): Promise<Record<string, unknown>> {
		try {
			const res = await this.api.post<Record<string, unknown>>(
				`/bank/loans/${loanId}/repay`,
				amount !== null ? { amount } : undefined
			);
			return res ?? { success: true };
		} catch (err) {
			throw wrap(err, 'repayLoan');
		}
	}

	async getBankAccounts(): Promise<BankAccount[]> {
		try {
			return rows(await this.api.get<unknown>('/bank/accounts')).map(bankAccountFromMap);
		} catch (err) {
			throw wrap(err, 'getBankAccounts');
		}
	}

	async getBankTransactions(accountId: string): Promise<BankTransaction[]> {
		try {
			const query = accountId ? { accountId } : undefined;
			return rows(await this.api.get<unknown>('/bank/transactions', query)).map(
				bankTransactionFromMap
			);
		} catch (err) {
			throw wrap(err, 'getBankTransactions');
		}
	}
}
