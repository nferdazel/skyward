import { ApiError } from '$lib/core/api/errors';
import type { ApiClient } from '$lib/core/api/api-client';
import {
	bankTransactionFromMap,
	type BankTransaction
} from '$lib/features/bank/domain/bank-models';
import {
	emptyFinanceSnapshot,
	financeHistoryFromMap,
	financeSnapshotFromMap,
	type FinanceHistoryPoint,
	type FinanceSnapshot
} from '../domain/finance-snapshot';

export class FinanceGatewayError extends Error {
	readonly operation: string;
	constructor(message: string, operation: string) {
		super(message);
		this.name = 'FinanceGatewayError';
		this.operation = operation;
	}
}

function wrap(err: unknown, operation: string): FinanceGatewayError {
	if (err instanceof ApiError) return new FinanceGatewayError(err.message, operation);
	return new FinanceGatewayError(err instanceof Error ? err.message : String(err), operation);
}

function rows(v: unknown): Record<string, unknown>[] {
	return Array.isArray(v)
		? v.filter((m): m is Record<string, unknown> => !!m && typeof m === 'object')
		: [];
}

/** Operasi keuangan via skyward-api (Go REST). Port dari `GoFinanceGateway`. */
export class FinanceGateway {
	constructor(private readonly api: ApiClient) {}

	async loadTransactions(): Promise<BankTransaction[]> {
		try {
			return rows(await this.api.get<unknown>('/finance/transactions')).map(bankTransactionFromMap);
		} catch (err) {
			throw wrap(err, 'loadTransactions');
		}
	}

	async getFinanceSnapshot(): Promise<FinanceSnapshot> {
		try {
			const res = await this.api.get<Record<string, unknown>>('/finance/snapshot');
			return res ? financeSnapshotFromMap(res) : emptyFinanceSnapshot();
		} catch (err) {
			throw wrap(err, 'getFinanceSnapshot');
		}
	}

	async getFinancialSnapshots(): Promise<FinanceHistoryPoint[]> {
		try {
			return rows(await this.api.get<unknown>('/finance/history')).map(financeHistoryFromMap);
		} catch (err) {
			throw wrap(err, 'getFinancialSnapshots');
		}
	}
}
