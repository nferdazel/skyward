/**
 * Snapshot keuangan. Port dari Flutter `FinanceSnapshot`.
 * Semua angka dari server; klien hanya menyajikan.
 */
export interface FinanceSnapshot {
	actorId: string;
	isBot: boolean;
	companyName: string;
	cash: number;
	netWorth: number;
	ownedAircraftAssetValue: number;
	leasedAircraftMonthlyExposure: number;
	fleetCount: number;
	ownedFleetCount: number;
	leasedFleetCount: number;
	activeRouteCount: number;
	rollingRevenue30d: number;
	rollingExpense30d: number;
	rollingNet30d: number;
	ledgerWindowDays: number;
}

export function emptyFinanceSnapshot(): FinanceSnapshot {
	return {
		actorId: '',
		isBot: false,
		companyName: '',
		cash: 0,
		netWorth: 0,
		ownedAircraftAssetValue: 0,
		leasedAircraftMonthlyExposure: 0,
		fleetCount: 0,
		ownedFleetCount: 0,
		leasedFleetCount: 0,
		activeRouteCount: 0,
		rollingRevenue30d: 0,
		rollingExpense30d: 0,
		rollingNet30d: 0,
		ledgerWindowDays: 30
	};
}

function str(v: unknown, fallback = ''): string {
	return typeof v === 'string' ? v : fallback;
}
function num(v: unknown, fallback = 0): number {
	return typeof v === 'number' && Number.isFinite(v) ? v : fallback;
}

export function financeSnapshotFromMap(map: Record<string, unknown>): FinanceSnapshot {
	const rollingRevenue = num(map.rolling_revenue_30d, num(map.revenue_30d, 0));
	const rollingExpense = Math.abs(num(map.rolling_expense_30d, num(map.expense_30d, 0)));
	const isBotRaw = map.is_bot;
	const isBot = isBotRaw === true || isBotRaw === 'true' || isBotRaw === 1;
	return {
		actorId: str(map.actor_id ?? map.user_id),
		isBot,
		companyName: str(map.company_name),
		cash: num(map.cash, num(map.cash_balance, num(map.balance, 0))),
		netWorth: num(map.net_worth),
		ownedAircraftAssetValue: num(map.owned_aircraft_asset_value, num(map.fleet_value, 0)),
		leasedAircraftMonthlyExposure: num(
			map.leased_aircraft_monthly_exposure,
			num(map.monthly_lease_cost, 0)
		),
		fleetCount: num(map.fleet_count),
		ownedFleetCount: num(map.owned_fleet_count),
		leasedFleetCount: num(map.leased_fleet_count),
		activeRouteCount: num(map.active_route_count, num(map.route_count, 0)),
		rollingRevenue30d: rollingRevenue,
		rollingExpense30d: rollingExpense,
		rollingNet30d: num(map.rolling_net_30d, num(map.net_30d, rollingRevenue - rollingExpense)),
		ledgerWindowDays: num(map.ledger_window_days, 30)
	};
}

/** Snapshot riwayat (sparkline). Bentuk longgar; ambil field yang ada. */
export interface FinanceHistoryPoint {
	snapshotGameTime: string;
	cash: number;
	netWorth: number;
	activeRoutes: number;
	fleetCount: number;
}

export function financeHistoryFromMap(map: Record<string, unknown>): FinanceHistoryPoint {
	return {
		snapshotGameTime: str(map.snapshot_game_time),
		cash: num(map.cash),
		netWorth: num(map.net_worth),
		activeRoutes: num(map.active_routes),
		fleetCount: num(map.fleet_count)
	};
}
