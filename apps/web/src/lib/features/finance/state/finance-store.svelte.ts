import type { FinanceGateway } from '../data/finance-gateway';
import type { BankTransaction } from '$lib/features/bank/domain/bank-models';
import {
	emptyFinanceSnapshot,
	type FinanceHistoryPoint,
	type FinanceSnapshot
} from '../domain/finance-snapshot';

export interface FinanceState {
	loading: boolean;
	snapshot: FinanceSnapshot;
	history: FinanceHistoryPoint[];
	transactions: BankTransaction[];
	error: string | null;
}

/**
 * Store keuangan. Port dari `FinanceCubit`.
 *
 * Memuat snapshot, riwayat (sparkline), dan transaksi. Agregasi laporan IFRS
 * dilakukan di domain (`ifrs-report-builder`), bukan di sini.
 */
export class FinanceStore {
	state = $state<FinanceState>({
		loading: false,
		snapshot: emptyFinanceSnapshot(),
		history: [],
		transactions: [],
		error: null
	});

	constructor(private readonly gateway: FinanceGateway) {}

	async load(): Promise<void> {
		this.state = { ...this.state, loading: true, error: null };
		try {
			const [snapshot, history, transactions] = await Promise.all([
				this.gateway.getFinanceSnapshot(),
				this.gateway.getFinancialSnapshots(),
				this.gateway.loadTransactions()
			]);
			this.state = { loading: false, snapshot, history, transactions, error: null };
		} catch (err) {
			this.state = {
				...this.state,
				loading: false,
				error: err instanceof Error ? err.message : String(err)
			};
		}
	}

	async refresh(): Promise<void> {
		try {
			const [snapshot, transactions] = await Promise.all([
				this.gateway.getFinanceSnapshot(),
				this.gateway.loadTransactions()
			]);
			this.state = { ...this.state, snapshot, transactions };
		} catch (err) {
			this.state = { ...this.state, error: err instanceof Error ? err.message : String(err) };
		}
	}
}
