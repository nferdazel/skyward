import type { BankTransaction } from '$lib/features/bank/domain/bank-models';
import type { FinanceSnapshot } from './finance-snapshot';
import * as IfrsCategory from './ifrs-category';

/**
 * Menyusun laporan gaya IFRS dari data mentah. Port dari Flutter
 * `IfrsReportBuilder`.
 *
 * Klasifikasi di sini sengaja BUKAN `IfrsCategory` penuh: laporan memakai alias
 * bentuk pendek (`fuel`, `crew`, `maintenance`, `aircraft_lease_idle`) dan
 * bucket arus kas berbasis tanda/transactionType — semantik laporan, bukan
 * pengelompokan tampilan. Menyatukannya akan mengubah angka yang dilaporkan.
 *
 * Ini BUKAN ekonomi otoritatif: hanya agregasi tampilan dari transaksi yang
 * sudah dicatat server.
 */

export interface IncomeStatement {
	ticketSales: number;
	cargoRevenue: number;
	totalRevenue: number;
	fuel: number;
	crew: number;
	maintenance: number;
	airportFees: number;
	fleetLeasing: number;
	hangarRepairs: number;
	totalOperatingCosts: number;
	grossProfit: number;
	netIncome: number;
}

export interface BalanceSheet {
	cash: number;
	fleetNetBookValue: number;
	totalAssets: number;
	outstandingLoans: number;
	totalLiabilities: number;
	netWorth: number;
	totalEquity: number;
	leasedAircraftMonthlyExposure: number;
	leasedFleetCount: number;
}

export interface CashFlows {
	revenueInflows: number;
	operatingOutflows: number;
	operatingCashFlow: number;
	capitalExpenditure: number;
	aircraftSales: number;
	investingCashFlow: number;
	loanProceeds: number;
	loanRepayments: number;
	financingCashFlow: number;
	netCashChange: number;
}

const abs = (n: number) => Math.abs(n);

export function buildIncomeStatement(transactions: BankTransaction[]): IncomeStatement {
	let ticketSales = 0;
	let cargoRevenue = 0;
	for (const txn of transactions) {
		if (txn.transactionType !== 'credit') continue;
		const sub = txn.ifrsSubcategory ?? '';
		const amt = abs(txn.amount);
		if (IfrsCategory.ticketSalesSubcategories.has(sub)) ticketSales += amt;
		else if (IfrsCategory.cargoRevenueSubcategories.has(sub)) cargoRevenue += amt;
	}

	let fuel = 0;
	let crew = 0;
	let maintenance = 0;
	let airportFees = 0;
	let fleetLeasing = 0;
	let hangarRepairs = 0;
	for (const txn of transactions) {
		if (txn.transactionType !== 'debit') continue;
		const sub = txn.ifrsSubcategory ?? '';
		const cat = txn.ifrsCategory ?? '';
		const amt = abs(txn.amount);
		if (IfrsCategory.fuelSubcategories.has(sub) || (cat === 'cogs' && sub === '')) {
			fuel += amt;
		} else if (IfrsCategory.crewSubcategories.has(sub)) {
			crew += amt;
		} else if (IfrsCategory.maintenanceSubcategories.has(sub)) {
			maintenance += amt;
		} else if (IfrsCategory.airportFeeSubcategories.has(sub)) {
			airportFees += amt;
		} else if (IfrsCategory.leaseSubcategories.has(sub)) {
			fleetLeasing += amt;
		} else if (IfrsCategory.repairSubcategories.has(sub)) {
			hangarRepairs += amt;
		}
	}

	const totalRevenue = ticketSales + cargoRevenue;
	const totalOperatingCosts =
		fuel + crew + maintenance + airportFees + fleetLeasing + hangarRepairs;
	const grossProfit = totalRevenue - totalOperatingCosts;

	return {
		ticketSales,
		cargoRevenue,
		totalRevenue,
		fuel,
		crew,
		maintenance,
		airportFees,
		fleetLeasing,
		hangarRepairs,
		totalOperatingCosts,
		grossProfit,
		netIncome: grossProfit
	};
}

export function buildBalanceSheet(
	snapshot: FinanceSnapshot,
	outstandingLoans: number
): BalanceSheet {
	const cash = snapshot.cash;
	const fleetNetBookValue = snapshot.ownedAircraftAssetValue;
	const totalAssets = cash + fleetNetBookValue;
	const totalLiabilities = outstandingLoans;
	// Equity = residual supaya neraca selalu seimbang.
	const totalEquity = totalAssets - totalLiabilities;
	return {
		cash,
		fleetNetBookValue,
		totalAssets,
		outstandingLoans,
		totalLiabilities,
		netWorth: totalEquity,
		totalEquity,
		leasedAircraftMonthlyExposure: snapshot.leasedAircraftMonthlyExposure,
		leasedFleetCount: snapshot.leasedFleetCount
	};
}

export function buildCashFlows(transactions: BankTransaction[]): CashFlows {
	let revenueInflows = 0;
	let operatingOutflows = 0;
	for (const txn of transactions) {
		const cat = txn.ifrsCategory ?? '';
		const sub = txn.ifrsSubcategory ?? '';
		const amt = abs(txn.amount);
		if (txn.transactionType === 'credit' && IfrsCategory.isOperatingInflow(cat, sub)) {
			revenueInflows += amt;
		}
		if (txn.transactionType === 'debit' && IfrsCategory.isOperatingOutflow(cat, sub)) {
			operatingOutflows += amt;
		}
	}
	const operatingCashFlow = revenueInflows - operatingOutflows;

	let capitalExpenditure = 0;
	let aircraftSales = 0;
	for (const txn of transactions) {
		const sub = txn.ifrsSubcategory ?? '';
		const amt = abs(txn.amount);
		if (txn.transactionType === 'debit' && IfrsCategory.isCapitalExpenditure(sub)) {
			capitalExpenditure += amt;
		} else if (txn.transactionType === 'credit' && IfrsCategory.isAircraftSale(sub)) {
			aircraftSales += amt;
		}
	}
	const investingCashFlow = aircraftSales - capitalExpenditure;

	let loanProceeds = 0;
	let loanRepayments = 0;
	for (const txn of transactions) {
		const sub = txn.ifrsSubcategory ?? '';
		const amt = abs(txn.amount);
		if (IfrsCategory.isFinancingInflow(sub) && txn.transactionType === 'credit') {
			loanProceeds += amt;
		} else if (IfrsCategory.isFinancingOutflow(sub) && txn.transactionType === 'debit') {
			loanRepayments += amt;
		}
	}
	const financingCashFlow = loanProceeds - loanRepayments;

	return {
		revenueInflows,
		operatingOutflows,
		operatingCashFlow,
		capitalExpenditure,
		aircraftSales,
		investingCashFlow,
		loanProceeds,
		loanRepayments,
		financingCashFlow,
		netCashChange: operatingCashFlow + investingCashFlow + financingCashFlow
	};
}

export function isBalanced(sheet: BalanceSheet): boolean {
	return Math.abs(sheet.totalAssets - (sheet.totalLiabilities + sheet.totalEquity)) < 1;
}
