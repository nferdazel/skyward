import type { AppUser } from '$lib/features/auth/domain/user';
import type { SimulationState } from '$lib/features/simulation/state/simulation-store.svelte';
import type { UserFleetAircraft } from '$lib/features/fleet/domain/fleet-models';
import { isMaintenanceGrounded } from '$lib/features/fleet/domain/fleet-models';
import type { UserRoute } from '$lib/features/routes/domain/route-models';
import type { RoutePlanAssessment } from '$lib/features/routes/domain/route-assessment';
import type { FinanceSnapshot } from '$lib/features/finance/domain/finance-snapshot';
import type { BankTransaction } from '$lib/features/bank/domain/bank-models';
import type { LeaderboardEntry } from '$lib/features/leaderboard/domain/leaderboard-models';
import { colors } from '$lib/core/theme/tokens';

/**
 * Derived "command deck" overview. Ported from Flutter `OverviewSnapshot`.
 *
 * This is DISPLAY aggregation, not authoritative economics: economic figures
 * (route contribution, wear) come from the server's `/routes/assess/batch`;
 * this module only buckets and formats them. "Grounded" is a local predicate
 * (condition vs the player's threshold), not an economic calculation.
 */
export interface OverviewPriority {
	label: string;
	description: string;
	navigateToFleet: boolean;
}

export interface OverviewInputs {
	user: AppUser;
	sim: SimulationState;
	fleet: UserFleetAircraft[];
	routes: UserRoute[];
	assessments: Record<string, RoutePlanAssessment>;
	finance: FinanceSnapshot | null;
	/** True when the ledger has any expenses (drives coverage copy). */
	hasExpenseHistory: boolean;
	totalExpense: number;
	totalRevenue: number;
	totalLease: number;
	totalOperations: number;
	rankings: LeaderboardEntry[];
	/** Newest-last net-worth series for the KPI sparkline. */
	netWorthTrend: number[];
	/** Newest-last daily-profit series for the KPI sparkline. */
	profitTrend: number[];
}

export interface OverviewSnapshot {
	totalFleetCount: number;
	readyFleetCount: number;
	groundedCount: number;
	leasedCount: number;
	activeRoutes: number;
	riskyRoutes: number;
	averageCondition: number;
	totalSlackHours: number;
	averageFlightsPerRoute: number;
	runwayLabel: string;
	runwayColor: string;
	runwayDays: number | null;
	leaderGapLabel: string;
	leaderGapColor: string;
	avgFlightsPerRouteLabel: string;
	burnMixLabel: string;
	operationalStatus: string;
	operationalStatusColor: string;
	consecutiveNegativeDays: number;
	recoveryStreakDays: number;
	leadingBotArchetype: string;
	leadingBotStatus: string;
	leadingBotFleet: number;
	leadingBotRevenue: number;
	idleReadyFleetCount: number;
	assignedFleetCount: number;
	topRouteRiskLabel: string;
	bestRouteYieldLabel: string;
	priorities: OverviewPriority[];
	bankruptcyRiskLevel: number;
	bankruptcyRiskLabel: string;
}

const DANGER_DAYS = 14;
const WARNING_DAYS = 45;

/** Map runway days to indicator label + colour. Ported from `RunwayIndicator`. */
export function runwayIndicator(days: number | null): { label: string; color: string } {
	if (days === null) return { label: 'Unknown', color: colors.neutral };
	const color =
		days < DANGER_DAYS ? colors.error : days < WARNING_DAYS ? colors.warning : colors.success;
	return { label: `${days.toFixed(1)}d`, color };
}

function operationalStatusColor(status: string): string {
	switch (status) {
		case 'Distress':
			return colors.error;
		case 'Maintenance':
			return colors.warning;
		case 'Recovery':
			return colors.teal;
		default:
			return colors.success;
	}
}

export function buildOverviewSnapshot(i: OverviewInputs): OverviewSnapshot {
	const { user, sim } = i;

	const readyFleet = i.fleet.filter(
		(a) => a.status === 'active' && !isMaintenanceGrounded(a, user.autoGroundingThreshold)
	).length;
	const grounded = i.fleet.filter(
		(a) => a.status === 'grounded' || isMaintenanceGrounded(a, user.autoGroundingThreshold)
	).length;
	const leased = i.fleet.filter((a) => a.acquisitionType === 'lease').length;
	const assignedIds = new Set(
		i.routes.map((r) => r.assignedAircraftId).filter((v): v is string => v !== null)
	);
	const idleReadyFleet = i.fleet.filter(
		(a) =>
			a.status === 'active' &&
			!isMaintenanceGrounded(a, user.autoGroundingThreshold) &&
			!assignedIds.has(a.id)
	).length;
	const avgCondition =
		i.fleet.length === 0 ? 100 : i.fleet.reduce((s, a) => s + a.condition, 0) / i.fleet.length;

	let slackHours = 0;
	let riskyRoutes = 0;
	let totalFlights = 0;
	let topRiskRoute: UserRoute | null = null;
	let topRiskScore = -1;
	let topYieldRoute: UserRoute | null = null;
	let topYieldValue = -Infinity;

	for (const route of i.routes) {
		totalFlights += route.flightsPerWeek;
		const aircraft = route.assignedAircraft;
		const requiresAssignment = aircraft === null;
		const isGrounded =
			aircraft !== null && isMaintenanceGrounded(aircraft, user.autoGroundingThreshold);
		const assessment = i.assessments[route.id];

		if (!requiresAssignment && assessment) {
			const unused = assessment.maxWeeklyFlights - assessment.allocatedFlightsPerWeek;
			slackHours += (unused > 0 ? unused : 0) * assessment.flightDurationHours;
			if (isGrounded || assessment.wear.netPerWeek > 0) riskyRoutes += 1;
		} else {
			riskyRoutes += 1;
		}

		const riskScore =
			(requiresAssignment ? 200 : 0) +
			(isGrounded ? 150 : 0) +
			(assessment?.wear.netPerWeek ?? 0) +
			(requiresAssignment ? 50 : 0);
		if (riskScore > topRiskScore) {
			topRiskScore = riskScore;
			topRiskRoute = route;
		}
		if (assessment && assessment.weeklyContribution > topYieldValue) {
			topYieldValue = assessment.weeklyContribution;
			topYieldRoute = route;
		}
	}

	const avgFlightsPerRoute = i.routes.length === 0 ? 0 : totalFlights / i.routes.length;
	const ledgerWindowDays = i.finance?.ledgerWindowDays ?? 30;
	const rollingExpense = i.finance?.rollingExpense30d ?? 0;
	const dailyBurn = ledgerWindowDays > 0 ? rollingExpense / ledgerWindowDays : 0;
	const runwayDays = rollingExpense > 0 && dailyBurn > 0 ? sim.cashBalance / dailyBurn : null;
	const runway = runwayIndicator(runwayDays);

	// Bankruptcy risk escalation (GAME-13). Critical at/below half the cash
	// threshold, or (only while cash is < 0) near the negative-day limit.
	const cash = sim.cashBalance;
	const negDays = sim.consecutiveNegativeDays;
	const criticalCashThreshold = sim.bankruptcyCashThreshold / 2.5;
	const criticalNegDays = Math.floor((sim.bankruptcyNegativeDaysThreshold * 2) / 3);
	let bankruptcyRiskLevel = 0;
	let bankruptcyRiskLabel = '';
	if (cash <= criticalCashThreshold || (cash < 0 && negDays >= criticalNegDays)) {
		bankruptcyRiskLevel = 2;
		bankruptcyRiskLabel = 'BANKRUPTCY CRITICAL';
	} else if (cash < 0) {
		bankruptcyRiskLevel = 1;
		bankruptcyRiskLabel = 'BANKRUPTCY WARNING';
	}

	const playerEntry = i.rankings.find((r) => !r.isBot && r.id === user.id) ?? null;
	const leader = i.rankings.length > 0 ? i.rankings[0] : null;
	const leaderGap =
		leader === null || playerEntry === null ? null : leader.netWorth - playerEntry.netWorth;
	const leaderGapLabel =
		leaderGap === null
			? '…'
			: leaderGap <= 0
				? 'World leader'
				: `$${new Intl.NumberFormat('en-US', { notation: 'compact', maximumFractionDigits: 1 }).format(leaderGap)}`;
	const leaderGapColor =
		leaderGap === null
			? colors.neutral
			: leaderGap <= 0
				? colors.success
				: leaderGap > 5_000_000
					? colors.warning
					: colors.accent;

	const botLeader = i.rankings.find((r) => r.isBot) ?? null;

	const priorities: OverviewPriority[] = [];
	if (user.operationalStatus === 'Distress') {
		priorities.push({
			label: 'Stabilize cash',
			description: 'You are in distress — reduce burn and raise cash.',
			navigateToFleet: false
		});
	}
	if (grounded > 0) {
		priorities.push({
			label: 'Repair fleet',
			description: `${grounded} aircraft are grounded.`,
			navigateToFleet: true
		});
	}
	if (leased > 0 && i.totalLease > i.totalRevenue) {
		priorities.push({
			label: 'Tighten leases',
			description: 'Lease costs exceed ticket sales.',
			navigateToFleet: false
		});
	}
	if (riskyRoutes > 0) {
		priorities.push({
			label: 'Review pricing',
			description: `${riskyRoutes} routes are losing money.`,
			navigateToFleet: false
		});
	}
	if (runwayDays !== null && runwayDays < 45) {
		priorities.push({
			label: 'Assign aircraft',
			description: 'Runway is short — put idle aircraft to work.',
			navigateToFleet: false
		});
	}
	if (user.operationalStatus === 'Recovery') {
		priorities.push({
			label: 'Protect recovery',
			description: 'Keep the streak going.',
			navigateToFleet: false
		});
	}
	if (leaderGap !== null && leaderGap > 5_000_000) {
		priorities.push({
			label: 'Expand',
			description: 'The leader is far ahead.',
			navigateToFleet: false
		});
	}

	const burnMixLabel =
		!i.hasExpenseHistory || i.totalExpense <= 0
			? 'No expense history'
			: `${Math.round((i.totalLease / i.totalExpense) * 100)}% lease / ${Math.round((i.totalOperations / i.totalExpense) * 100)}% ops`;

	return {
		totalFleetCount: i.fleet.length,
		readyFleetCount: readyFleet,
		groundedCount: grounded,
		leasedCount: leased,
		activeRoutes: i.routes.length,
		riskyRoutes,
		averageCondition: avgCondition,
		totalSlackHours: slackHours,
		averageFlightsPerRoute: avgFlightsPerRoute,
		runwayLabel: runway.label,
		runwayColor: runway.color,
		runwayDays,
		leaderGapLabel,
		leaderGapColor,
		avgFlightsPerRouteLabel:
			i.routes.length === 0 ? 'No route coverage' : `${avgFlightsPerRoute.toFixed(1)}/wk`,
		burnMixLabel,
		operationalStatus: user.operationalStatus,
		operationalStatusColor: operationalStatusColor(user.operationalStatus),
		consecutiveNegativeDays: sim.consecutiveNegativeDays,
		recoveryStreakDays: sim.recoveryStreakDays,
		leadingBotArchetype: botLeader?.archetype ?? '…',
		leadingBotStatus: botLeader?.status ?? '…',
		leadingBotFleet: botLeader?.fleetSize ?? 0,
		leadingBotRevenue: botLeader?.monthlyRevenue ?? 0,
		idleReadyFleetCount: idleReadyFleet,
		assignedFleetCount: assignedIds.size,
		topRouteRiskLabel:
			topRiskRoute === null
				? 'No route risk'
				: `${topRiskRoute.originIata} → ${topRiskRoute.destinationIata}`,
		bestRouteYieldLabel:
			topYieldRoute === null
				? 'No yield signal'
				: `${topYieldRoute.originIata} → ${topYieldRoute.destinationIata}`,
		priorities: priorities.slice(0, 3),
		bankruptcyRiskLevel,
		bankruptcyRiskLabel
	};
}

/** Sum helpers for the finance slice the overview needs. */
export function financeTotals(transactions: BankTransaction[]): {
	totalExpense: number;
	totalRevenue: number;
	totalLease: number;
	totalOperations: number;
} {
	let totalExpense = 0;
	let totalRevenue = 0;
	let totalLease = 0;
	let totalOperations = 0;
	for (const t of transactions) {
		const amt = Math.abs(t.amount);
		if (t.transactionType === 'credit') {
			totalRevenue += amt;
			continue;
		}
		totalExpense += amt;
		const sub = t.ifrsSubcategory ?? '';
		if (sub.startsWith('aircraft_lease')) totalLease += amt;
		else totalOperations += amt;
	}
	return { totalExpense, totalRevenue, totalLease, totalOperations };
}
