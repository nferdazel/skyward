/** Akun bank. Port dari Flutter `BankAccount`. */
export interface BankAccount {
	id: string;
	userId: string;
	accountType: string;
	balance: number;
	createdAt: string | null;
	updatedAt: string | null;
}

function str(v: unknown, fallback = ''): string {
	return typeof v === 'string' ? v : fallback;
}
function num(v: unknown, fallback = 0): number {
	return typeof v === 'number' && Number.isFinite(v) ? v : fallback;
}
function dateStr(v: unknown): string | null {
	if (typeof v === 'string' && v) return v;
	return null;
}

export function bankAccountFromMap(map: Record<string, unknown>): BankAccount {
	return {
		id: str(map.id),
		userId: str(map.user_id),
		accountType: str(map.account_type, 'operating'),
		balance: num(map.balance),
		createdAt: dateStr(map.created_at),
		updatedAt: dateStr(map.updated_at)
	};
}

export function isOperating(account: BankAccount): boolean {
	return account.accountType === 'operating';
}

/** Transaksi bank (arus uang kanonik). Port dari Flutter `BankTransaction`. */
export interface BankTransaction {
	id: string;
	accountId: string;
	userId: string;
	transactionType: string;
	amount: number;
	balanceAfter: number;
	description: string | null;
	ifrsCategory: string | null;
	ifrsSubcategory: string | null;
	gameDate: string | null;
}

export function bankTransactionFromMap(map: Record<string, unknown>): BankTransaction {
	return {
		id: str(map.id),
		accountId: str(map.account_id),
		userId: str(map.user_id),
		transactionType: str(map.transaction_type, 'debit'),
		amount: num(map.amount),
		balanceAfter: num(map.balance_after),
		description: typeof map.description === 'string' ? map.description : null,
		ifrsCategory: typeof map.ifrs_category === 'string' ? map.ifrs_category : null,
		ifrsSubcategory: typeof map.ifrs_subcategory === 'string' ? map.ifrs_subcategory : null,
		gameDate: dateStr(map.game_date)
	};
}
