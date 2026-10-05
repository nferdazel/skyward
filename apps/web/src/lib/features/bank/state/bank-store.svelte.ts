import type { BankGateway, LoanType } from '../data/bank-gateway';
import type { BankAccount, BankTransaction } from '../domain/bank-models';
import type { CreditReport, CreditScoreSnapshot, Loan } from '../domain/loan-models';

export interface BankState {
	loading: boolean;
	accounts: BankAccount[];
	transactions: BankTransaction[];
	loans: Loan[];
	credit: CreditReport | null;
	creditHistory: CreditScoreSnapshot[];
	error: string | null;
}

/**
 * Store bank. Port dari `BankCubit`.
 *
 * Memuat akun, pinjaman, laporan kredit, riwayat kredit, dan transaksi; mutasi
 * ambil pinjaman / bayar / refinance / financing; refetch saat event realtime
 * `loans` dan `bank_transactions`.
 */
export class BankStore {
	state = $state<BankState>({
		loading: false,
		accounts: [],
		transactions: [],
		loans: [],
		credit: null,
		creditHistory: [],
		error: null
	});

	constructor(private readonly gateway: BankGateway) {}

	async load(accountId = ''): Promise<void> {
		this.state = { ...this.state, loading: true, error: null };
		try {
			const [accounts, loans, credit, creditHistory, transactions] = await Promise.all([
				this.gateway.getBankAccounts(),
				this.gateway.getLoans(),
				this.gateway.getCreditReport(),
				this.gateway.getCreditHistory(),
				this.gateway.getBankTransactions(accountId)
			]);
			this.state = {
				loading: false,
				accounts,
				loans,
				credit,
				creditHistory,
				transactions,
				error: null
			};
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
			const [accounts, loans, credit, creditHistory] = await Promise.all([
				this.gateway.getBankAccounts(),
				this.gateway.getLoans(),
				this.gateway.getCreditReport(),
				this.gateway.getCreditHistory()
			]);
			this.state = { ...this.state, accounts, loans, credit, creditHistory };
		} catch (err) {
			this.state = { ...this.state, error: err instanceof Error ? err.message : String(err) };
		}
	}

	private async mutate(action: () => Promise<unknown>): Promise<boolean> {
		this.state = { ...this.state, error: null };
		try {
			await action();
			await this.refresh();
			return true;
		} catch (err) {
			this.state = { ...this.state, error: err instanceof Error ? err.message : String(err) };
			return false;
		}
	}

	takeLoan(input: {
		principal: number;
		termWeeks: number;
		loanType?: LoanType;
		collateralAircraftId?: string | null;
	}): Promise<boolean> {
		return this.mutate(() => this.gateway.takeLoan(input));
	}

	repay(loanId: string, amount: number | null): Promise<boolean> {
		return this.mutate(() => this.gateway.repayLoan(loanId, amount));
	}

	refinance(loanId: string): Promise<boolean> {
		return this.mutate(() => this.gateway.refinanceLoan(loanId));
	}

	financeAircraft(input: {
		aircraftModelId: string;
		downPaymentPct: number;
		termMonths: number;
	}): Promise<boolean> {
		return this.mutate(() => this.gateway.financeAircraft(input));
	}

	/** Akun operasional (kas kanonik). */
	get operatingAccount(): BankAccount | null {
		return this.state.accounts.find((a) => a.accountType === 'operating') ?? null;
	}
}
