/** Entri papan peringkat. Port dari Flutter `LeaderboardEntry`. */
export interface LeaderboardEntry {
	id: string;
	companyName: string;
	ceoName: string;
	isBot: boolean;
	archetype: string;
	cash: number;
	netWorth: number;
	fleetSize: number;
	monthlyRevenue: number;
	status: string;
	consecutiveNegativeDays: number;
	creditTier: string | null;
}

function str(v: unknown, fallback = ''): string {
	return typeof v === 'string' ? v : fallback;
}
function num(v: unknown, fallback = 0): number {
	return typeof v === 'number' && Number.isFinite(v) ? v : fallback;
}

export function leaderboardEntryFromMap(map: Record<string, unknown>): LeaderboardEntry {
	return {
		id: str(map.id),
		companyName: str(map.company_name),
		ceoName: str(map.ceo_name),
		isBot: map.is_bot === true,
		archetype: str(map.archetype, 'Player'),
		cash: num(map.cash),
		netWorth: num(map.net_worth),
		fleetSize: num(map.fleet_size),
		monthlyRevenue: num(map.monthly_revenue),
		status: str(map.status, 'Active'),
		consecutiveNegativeDays: num(map.consecutive_negative_days),
		creditTier: typeof map.credit_tier === 'string' ? map.credit_tier : null
	};
}

/** Analitik kompetitor. Port dari Flutter `CompetitorInsights`. */
export interface CompetitorInsights {
	companyName: string;
	ceoName: string;
	cash: number;
	netWorth: number;
	status: string;
	fleetBreakdown: Record<string, number>;
	networkRoutes: string[];
	fleetSize: number;
	monthlyRevenue: number;
}

export function competitorInsightsFromMap(map: Record<string, unknown>): CompetitorInsights {
	const rawFleet =
		map.fleet_breakdown && typeof map.fleet_breakdown === 'object'
			? (map.fleet_breakdown as Record<string, unknown>)
			: {};
	const fleetBreakdown: Record<string, number> = {};
	for (const [k, v] of Object.entries(rawFleet)) fleetBreakdown[k] = num(v);
	const networkRoutes = Array.isArray(map.network_routes) ? map.network_routes.map(String) : [];
	return {
		companyName: str(map.company_name),
		ceoName: str(map.ceo_name),
		cash: num(map.cash),
		netWorth: num(map.net_worth),
		status: str(map.status, 'Active'),
		fleetBreakdown,
		networkRoutes,
		fleetSize: num(map.fleet_size),
		monthlyRevenue: num(map.monthly_revenue)
	};
}

export const revenuePerAircraft = (c: CompetitorInsights): number =>
	c.fleetSize > 0 ? c.monthlyRevenue / c.fleetSize : 0;
export const netWorthPerAircraft = (c: CompetitorInsights): number =>
	c.fleetSize > 0 ? c.netWorth / c.fleetSize : 0;
