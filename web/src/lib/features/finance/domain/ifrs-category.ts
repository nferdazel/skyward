/**
 * Klasifikasi transaksi per kategori/subkategori IFRS. Port dari Flutter
 * `IfrsCategory`.
 *
 * Satu sumber kebenaran untuk membucket transaksi. `ifrs-report-builder`
 * sengaja punya aturan sendiri (alias bentuk pendek + bucket arus kas berbasis
 * tanda) — itu semantik laporan, bukan pengelompokan tampilan; jangan disatukan.
 */

export const ticketSalesSubcategories = new Set(['ticket_revenue', 'route_revenue']);
export const cargoRevenueSubcategories = new Set(['cargo_revenue']);
export const fuelSubcategories = new Set(['fuel', 'fuel_cost']);
export const crewSubcategories = new Set(['crew', 'crew_cost']);
export const maintenanceSubcategories = new Set(['maintenance', 'maintenance_cost']);
export const airportFeeSubcategories = new Set(['airport_fees']);
export const leaseSubcategories = new Set([
	'aircraft_lease',
	'aircraft_lease_idle',
	'aircraft_lease_init',
	'aircraft_lease_exit'
]);
export const repairSubcategories = new Set(['aircraft_repair']);
export const purchaseSubcategories = new Set(['aircraft_purchase', 'aircraft_purchase_deposit']);
export const capitalExpenditureSubcategories = new Set([
	'aircraft_purchase',
	'aircraft_purchase_deposit',
	'aircraft_lease_deposit'
]);
export const aircraftSaleSubcategory = 'aircraft_sale';
export const financingInflowSubcategories = new Set(['loan_disbursement']);
export const financingOutflowSubcategories = new Set([
	'loan_payment',
	'loan_repayment',
	'financing_payment'
]);

export function isTicketSales(category: string, subcategory: string): boolean {
	return (
		category === 'revenue' ||
		ticketSalesSubcategories.has(subcategory) ||
		cargoRevenueSubcategories.has(subcategory)
	);
}

export function isOperationsSubcategory(subcategory: string): boolean {
	return (
		fuelSubcategories.has(subcategory) ||
		crewSubcategories.has(subcategory) ||
		maintenanceSubcategories.has(subcategory) ||
		airportFeeSubcategories.has(subcategory)
	);
}

/**
 * Bucket metrik tidak saling eksklusif: kategori `cogs`/`opex` menangkap baris
 * yang subkategorinya lebih spesifik. `totalExpense` tidak dijumlahkan dari
 * bucket ini, jadi tidak ada penggandaan uang.
 */
export function isOperationsExpense(category: string, subcategory: string): boolean {
	return category === 'cogs' || category === 'opex' || isOperationsSubcategory(subcategory);
}

export function isLeaseExpense(category: string, subcategory: string): boolean {
	return leaseSubcategories.has(category) || leaseSubcategories.has(subcategory);
}

export function isRepairExpense(category: string, subcategory: string): boolean {
	return repairSubcategories.has(category) || repairSubcategories.has(subcategory);
}

export function isPurchaseExpense(category: string, subcategory: string): boolean {
	return purchaseSubcategories.has(category) || purchaseSubcategories.has(subcategory);
}

// ── Bucket arus kas (dipakai report builder) ──────────────────────────────────

export function isOperatingInflow(category: string, subcategory: string): boolean {
	return isTicketSales(category, subcategory);
}

export function isOperatingOutflow(category: string, subcategory: string): boolean {
	return (
		isOperationsExpense(category, subcategory) ||
		isLeaseExpense(category, subcategory) ||
		isRepairExpense(category, subcategory)
	);
}

export const isCapitalExpenditure = (subcategory: string) =>
	capitalExpenditureSubcategories.has(subcategory);
export const isAircraftSale = (subcategory: string) => subcategory === aircraftSaleSubcategory;
export const isFinancingInflow = (subcategory: string) =>
	financingInflowSubcategories.has(subcategory);
export const isFinancingOutflow = (subcategory: string) =>
	financingOutflowSubcategories.has(subcategory);

/** Grup tampilan untuk badge transaksi. */
export type IfrsGroup =
	'ticketSales' | 'operations' | 'lease' | 'repair' | 'purchase' | 'financing' | 'other';

/**
 * Peta key yang sudah di-resolve ke grup tampilannya. Pemanggil me-resolve key
 * sendiri karena mereka sengaja berbeda (ledger suka subcategory lalu fallback
 * ke category; bank panel memakai `subcategory ?? category`).
 */
export function groupFor(key: string): IfrsGroup {
	switch (key) {
		case 'ticket_revenue':
		case 'route_revenue':
		case 'cargo_revenue':
		case 'revenue':
			return 'ticketSales';
		case 'fuel':
		case 'fuel_cost':
		case 'crew':
		case 'crew_cost':
		case 'maintenance':
		case 'maintenance_cost':
		case 'airport_fees':
		case 'cogs':
		case 'opex':
			return 'operations';
		case 'aircraft_lease':
		case 'aircraft_lease_idle':
		case 'aircraft_lease_init':
		case 'aircraft_lease_exit':
		case 'aircraft_lease_deposit':
			return 'lease';
		case 'aircraft_repair':
			return 'repair';
		case 'aircraft_purchase':
		case 'aircraft_purchase_deposit':
			return 'purchase';
		case 'loan_payment':
		case 'loan_repayment':
		case 'loan_disbursement':
		case 'loan_refinance':
		case 'financing_payment':
		case 'financing':
			return 'financing';
		default:
			return 'other';
	}
}
