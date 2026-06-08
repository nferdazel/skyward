// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../presentation/widgets/app_card.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../finance/presentation/cubit/finance_cubit.dart';
import '../../../finance/presentation/cubit/finance_state.dart';
import '../../../fleet/domain/fleet_models.dart';
import '../../../fleet/presentation/cubit/fleet_cubit.dart';
import '../../../fleet/presentation/cubit/fleet_state.dart';
import '../../../leaderboard/domain/leaderboard_models.dart';
import '../../../leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../../leaderboard/presentation/cubit/leaderboard_state.dart';
import '../../../routes/domain/route_models.dart';
import '../../../routes/presentation/cubit/routes_cubit.dart';
import '../../../routes/presentation/cubit/routes_state.dart';
import '../../../simulation/presentation/cubit/simulation_cubit.dart';
import '../../../simulation/presentation/cubit/simulation_state.dart';

class OverviewTab extends StatelessWidget {
  final VoidCallback onNavigateToFleet;
  final VoidCallback onNavigateToRoutes;

  const OverviewTab({
    super.key,
    required this.onNavigateToFleet,
    required this.onNavigateToRoutes,
  });

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Center(child: Text(AppStrings.unauthorized));
    }

    final user = authState.user;
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return BlocBuilder<SimulationCubit, SimulationState>(
      builder: (context, simState) {
        final fleetState = context.select((FleetCubit cubit) => cubit.state);
        final routesState = context.select((RoutesCubit cubit) => cubit.state);
        final financeState = context.select(
          (FinanceCubit cubit) => cubit.state,
        );
        final leaderboardState = context.select(
          (LeaderboardCubit cubit) => cubit.state,
        );

        final overview = _OverviewSnapshot.fromStates(
          user: user,
          simState: simState,
          fleetState: fleetState,
          routesState: routesState,
          financeState: financeState,
          leaderboardState: leaderboardState,
        );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCEOHeaderCard(context, user, overview),
              const SizedBox(height: AppSpacing.sectionGap),
              _buildStatsSummaryGrid(
                context,
                simState,
                currencyFormat,
                overview,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              ResponsiveLayout(
                desktopBody: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildRouteRiskBoard(
                        context,
                        overview,
                        currencyFormat,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(child: _buildActionQueue(context, overview)),
                  ],
                ),
                mobileBody: Column(
                  children: [
                    _buildRouteRiskBoard(context, overview, currencyFormat),
                    const SizedBox(height: AppSpacing.sectionGap),
                    _buildActionQueue(context, overview),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCEOHeaderCard(
    BuildContext context,
    dynamic user,
    _OverviewSnapshot overview,
  ) {
    return AppCard(
      customBorder: Border(
        top: BorderSide(color: AppTheme.primary, width: 2.0),
        bottom: BorderSide(color: AppTheme.surfaceSubtle, width: 1.0),
        left: BorderSide(color: AppTheme.surfaceSubtle, width: 1.0),
        right: BorderSide(color: AppTheme.surfaceSubtle, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            user.companyName,
            style: AppTypography.screenTitleLarge,
          ),
          Text(
            '${AppStrings.ceoPrefix}: ${user.ceoName}',
            style: AppTypography.captionRegular.copyWith(
              color: AppTypography.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xxs,
            children: [
              _buildHeaderChip(
                AppStrings.fleetReadyLabel,
                '${overview.readyFleetCount}${AppStrings.airframesSuffix}',
                AppTheme.success,
              ),
              _buildHeaderChip(
                AppStrings.activeRoutesLabel,
                '${overview.activeRoutes}${AppStrings.routesSuffix}',
                AppTheme.primary,
              ),
              _buildHeaderChip(
                AppStrings.weeklySlackHoursLabel,
                '${overview.totalSlackHours.toStringAsFixed(1)}${AppStrings.hoursPerWeekSuffix}',
                AppTheme.info,
              ),
              _buildHeaderChip(
                AppStrings.operationalStatusLabel,
                overview.operationalStatus,
                overview.operationalStatusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSummaryGrid(
    BuildContext context,
    SimulationState simState,
    NumberFormat currencyFormat,
    _OverviewSnapshot overview,
  ) {
    return ResponsiveLayout(
      desktopBody: Row(
        children: [
          Expanded(
            child: _buildHUDMetricCard(
              context,
              AppStrings.liquidityPositionLabel,
              currencyFormat.format(simState.cashBalance),
              AppTheme.success,
            ),
          ),
          const SizedBox(width: AppSpacing.blockGap),
          Expanded(
            child: _buildHUDMetricCard(
              context,
              AppStrings.runwayEstimateLabel,
              overview.runwayLabel,
              overview.runwayColor,
            ),
          ),
          const SizedBox(width: AppSpacing.blockGap),
          Expanded(
            child: _buildHUDMetricCard(
              context,
              AppStrings.fleetReadyLabel,
              '${overview.readyFleetCount}/${overview.totalFleetCount}',
              AppTheme.info,
            ),
          ),
          const SizedBox(width: AppSpacing.blockGap),
          Expanded(
            child: _buildHUDMetricCard(
              context,
              AppStrings.networkPressureLabel,
              '${overview.riskyRoutes}/${overview.activeRoutes}',
              overview.riskyRoutes > 0 ? AppTheme.warning : AppTheme.success,
            ),
          ),
        ],
      ),
      mobileBody: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHUDMetricCard(
            context,
            AppStrings.liquidityPositionLabel,
            currencyFormat.format(simState.cashBalance),
            AppTheme.success,
          ),
          const SizedBox(height: AppSpacing.compactGap),
          _buildHUDMetricCard(
            context,
            AppStrings.runwayEstimateLabel,
            overview.runwayLabel,
            overview.runwayColor,
          ),
          const SizedBox(height: AppSpacing.compactGap),
          _buildHUDMetricCard(
            context,
            AppStrings.fleetReadyLabel,
            '${overview.readyFleetCount}/${overview.totalFleetCount}',
            AppTheme.info,
          ),
          const SizedBox(height: AppSpacing.compactGap),
          _buildHUDMetricCard(
            context,
            AppStrings.networkPressureLabel,
            '${overview.riskyRoutes}/${overview.activeRoutes}',
            overview.riskyRoutes > 0 ? AppTheme.warning : AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _buildHUDMetricCard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return AppCard(
      customBorder: Border(
        top: BorderSide(color: color, width: 2.0),
        bottom: BorderSide(color: AppTheme.surfaceSubtle, width: 1.0),
        left: BorderSide(color: AppTheme.surfaceSubtle, width: 1.0),
        right: BorderSide(color: AppTheme.surfaceSubtle, width: 1.0),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.badgeText.copyWith(
              color: AppTypography.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.sectionHeaderLarge.copyWith(
              fontFamily: AppTypography.badgeText.fontFamily,
              color: color,
              letterSpacing: 0.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteRiskBoard(
    BuildContext context,
    _OverviewSnapshot overview,
    NumberFormat currencyFormat,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, color: AppTheme.warning, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppStrings.routeRiskTitle,
                style: AppTypography.badgeText.copyWith(
                  color: AppTypography.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: AppTheme.surfaceSubtle, height: 1),
          const SizedBox(height: AppSpacing.md),
          _buildAdviceItem(
            context,
            AppStrings.averageConditionLabel,
            '${overview.averageCondition.toStringAsFixed(1)}% across active fleet',
          ),
          _buildAdviceItem(
            context,
            AppStrings.netYieldLabel,
            currencyFormat.format(overview.netYield),
          ),
          _buildAdviceItem(
            context,
            AppStrings.idleFleetLabel,
            '${overview.idleReadyFleetCount}${AppStrings.airframesSuffix} are ready but not assigned',
          ),
          _buildAdviceItem(
            context,
            AppStrings.topRouteRiskLabel,
            overview.topRouteRiskLabel,
          ),
          _buildAdviceItem(
            context,
            AppStrings.competitiveGapLabel,
            overview.leaderGapLabel,
          ),
          _buildAdviceItem(
            context,
            AppStrings.operationalStatusLabel,
            overview.operationalStatus,
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceItem(BuildContext context, String topic, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic,
                  style: AppTypography.badgeText.copyWith(
                    color: AppTheme.primary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  text,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppTypography.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionQueue(BuildContext context, _OverviewSnapshot overview) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_outlined,
                color: AppTheme.primary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                AppStrings.actionQueueTitle,
                style: AppTypography.badgeText.copyWith(
                  color: AppTypography.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(color: AppTheme.surfaceSubtle, height: 1),
          const SizedBox(height: AppSpacing.md),
          if (overview.priorities.isEmpty)
            Text(
              AppStrings.noUrgentFailures,
              style: AppTypography.bodyMedium.copyWith(
                color: AppTypography.textSecondary,
                height: 1.5,
              ),
            )
          else
            ...overview.priorities.map(
              (priority) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _buildActionButton(
                  context,
                  priority.label,
                  priority.description,
                  priority.navigateToFleet
                      ? onNavigateToFleet
                      : onNavigateToRoutes,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.captionLight.copyWith(
              color: AppTypography.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: AppTypography.badgeText.copyWith(
              color: color,
              letterSpacing: 0.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    String description,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: AppCard(
        backgroundColor: AppTheme.surface3,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.badgeText.copyWith(
                      color: AppTheme.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs - AppSpacing.xxs),
                  Text(
                    description,
                    style: AppTypography.captionRegular.copyWith(
                      color: AppTypography.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.arrow_right_alt, color: AppTheme.primary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _OverviewPriority {
  final String label;
  final String description;
  final bool navigateToFleet;

  const _OverviewPriority({
    required this.label,
    required this.description,
    required this.navigateToFleet,
  });
}

class _OverviewSnapshot {
  final int totalFleetCount;
  final int readyFleetCount;
  final int groundedCount;
  final int leasedCount;
  final int activeRoutes;
  final int riskyRoutes;
  final double averageCondition;
  final double totalSlackHours;
  final double averageFlightsPerRoute;
  final double leaseExposure;
  final double netYield;
  final bool hasExpenseHistory;
  final bool revenueCoverageHealthy;
  final String runwayLabel;
  final Color runwayColor;
  final String leaderGapLabel;
  final Color leaderGapColor;
  final String avgFlightsPerRouteLabel;
  final String burnMixLabel;
  final String operationalStatus;
  final Color operationalStatusColor;
  final int consecutiveNegativeDays;
  final int recoveryStreakDays;
  final String leadingBotArchetype;
  final String leadingBotStatus;
  final int leadingBotFleet;
  final double leadingBotRevenue;
  final int idleReadyFleetCount;
  final int assignedFleetCount;
  final String topRouteRiskLabel;
  final String bestRouteYieldLabel;
  final List<_OverviewPriority> priorities;

  const _OverviewSnapshot({
    required this.totalFleetCount,
    required this.readyFleetCount,
    required this.groundedCount,
    required this.leasedCount,
    required this.activeRoutes,
    required this.riskyRoutes,
    required this.averageCondition,
    required this.totalSlackHours,
    required this.averageFlightsPerRoute,
    required this.leaseExposure,
    required this.netYield,
    required this.hasExpenseHistory,
    required this.revenueCoverageHealthy,
    required this.runwayLabel,
    required this.runwayColor,
    required this.leaderGapLabel,
    required this.leaderGapColor,
    required this.avgFlightsPerRouteLabel,
    required this.burnMixLabel,
    required this.operationalStatus,
    required this.operationalStatusColor,
    required this.consecutiveNegativeDays,
    required this.recoveryStreakDays,
    required this.leadingBotArchetype,
    required this.leadingBotStatus,
    required this.leadingBotFleet,
    required this.leadingBotRevenue,
    required this.idleReadyFleetCount,
    required this.assignedFleetCount,
    required this.topRouteRiskLabel,
    required this.bestRouteYieldLabel,
    required this.priorities,
  });

  static _OverviewSnapshot fromStates({
    required dynamic user,
    required SimulationState simState,
    required FleetState fleetState,
    required RoutesState routesState,
    required FinanceState financeState,
    required LeaderboardState leaderboardState,
  }) {
    final fleet = fleetState is FleetDataState
        ? fleetState.fleet
        : const <UserFleetAircraft>[];
    final routes = routesState is RoutesDataState
        ? routesState.routes
        : const <UserRoute>[];
    final finance = financeState is FinanceDataState ? financeState : null;
    final rankings = leaderboardState is LeaderboardLoaded
        ? leaderboardState.rankings
        : const <LeaderboardEntry>[];

    final readyFleet = fleet
        .where(
          (f) =>
              f.status == 'active' &&
              !f.isMaintenanceGrounded(user.autoGroundingThreshold),
        )
        .length;
    final grounded = fleet
        .where(
          (f) =>
              f.status == 'grounded' ||
              f.isMaintenanceGrounded(user.autoGroundingThreshold),
        )
        .length;
    final leased = fleet.where((f) => f.acquisitionType == 'lease').length;
    final assignedFleetIds = routes
        .map((route) => route.assignedAircraftId)
        .whereType<String>()
        .toSet();
    final idleReadyFleet = fleet
        .where(
          (aircraft) =>
              aircraft.status == 'active' &&
              !aircraft.isMaintenanceGrounded(user.autoGroundingThreshold) &&
              !assignedFleetIds.contains(aircraft.id),
        )
        .length;
    final assignedFleetCount = assignedFleetIds.length;
    final avgCondition = fleet.isEmpty
        ? 100.0
        : fleet.map((f) => f.condition).reduce((a, b) => a + b) / fleet.length;

    double slackHours = 0.0;
    int riskyRoutes = 0;
    double totalFlights = 0.0;
    UserRoute? topRiskRoute;
    double topRiskScore = -1.0;
    UserRoute? topYieldRoute;
    double topYieldValue = -999999999.0;
    for (final route in routes) {
      totalFlights += route.flightsPerWeek;
      final preview = route.buildMaintenancePreview(
        user.autoGroundingThreshold,
      );
      final assessment = route.assignedAircraft == null
          ? null
          : UserRoute.buildPlanningAssessment(
              origin: route.origin,
              destination: route.destination,
              distanceKm: route.distanceKm,
              ticketPrice: route.ticketPrice,
              flightsPerWeek: route.flightsPerWeek,
              availableAircraft: [route.assignedAircraft!],
              autoGroundingThreshold: user.autoGroundingThreshold,
            );
      if (!preview.requiresAircraftAssignment) {
        slackHours += preview.maintenanceHoursPerWeek;
        if (preview.isGrounded || preview.netHealthImpactPercent > 0.0) {
          riskyRoutes += 1;
        }
      } else {
        riskyRoutes += 1;
      }

      final riskScore =
          (preview.requiresAircraftAssignment ? 200.0 : 0.0) +
          (preview.isGrounded ? 150.0 : 0.0) +
          preview.netHealthImpactPercent +
          (route.assignedAircraft == null ? 50.0 : 0.0);
      if (riskScore > topRiskScore) {
        topRiskScore = riskScore;
        topRiskRoute = route;
      }
      if (assessment != null && assessment.weeklyContribution > topYieldValue) {
        topYieldValue = assessment.weeklyContribution;
        topYieldRoute = route;
      }
    }

    final avgFlightsPerRoute = routes.isEmpty
        ? 0.0
        : totalFlights / routes.length;
    final totalExpense = finance?.totalExpense ?? 0.0;
    final runwayDays = totalExpense > 0
        ? simState.cashBalance / (totalExpense / 30.0)
        : null;
    final runwayLabel = runwayDays == null
        ? AppStrings.runwayUnknown
        : '${runwayDays.toStringAsFixed(1)}${AppStrings.daysSuffix}';
    final runwayColor = runwayDays == null
        ? AppTheme.info
        : (runwayDays < 14
              ? AppTheme.error
              : (runwayDays < 45 ? AppTheme.warning : AppTheme.success));

    final playerEntry = rankings
        .where((r) => !r.isBot)
        .cast<LeaderboardEntry?>()
        .firstWhere((entry) => entry?.id == user.id, orElse: () => null);
    final leader = rankings.isNotEmpty ? rankings.first : null;
    final leaderGap = leader == null || playerEntry == null
        ? null
        : (leader.netWorth - playerEntry.netWorth);
    final leaderGapLabel = leaderGap == null
        ? AppStrings.loadingLabel
        : (leaderGap <= 0
              ? AppStrings.worldLeaderLabel
              : NumberFormat.compactCurrency(symbol: '\$').format(leaderGap));
    final leaderGapColor = leaderGap == null
        ? AppTheme.info
        : (leaderGap <= 0
              ? AppTheme.success
              : (leaderGap > 5000000 ? AppTheme.warning : AppTheme.primary));

    final botLeader = rankings.where((r) => r.isBot).isEmpty
        ? null
        : rankings.where((r) => r.isBot).first;
    final operationalStatus = user.operationalStatus;
    final operationalStatusColor = switch (operationalStatus) {
      'Distress' => AppTheme.error,
      'Maintenance' => AppTheme.warning,
      'Recovery' => AppTheme.info,
      _ => AppTheme.success,
    };

    final priorities = <_OverviewPriority>[];
    if (operationalStatus == 'Distress') {
      priorities.add(
        const _OverviewPriority(
          label: AppStrings.overviewStabilizeCashAction,
          description: AppStrings.overviewDistressWarning,
          navigateToFleet: false,
        ),
      );
    }
    if (grounded > 0) {
      priorities.add(
        const _OverviewPriority(
          label: AppStrings.overviewRepairFleetAction,
          description: AppStrings.overviewGroundedWarning,
          navigateToFleet: true,
        ),
      );
    }
    if (leased > 0 &&
        finance != null &&
        finance.totalLease > finance.totalTicketSales) {
      priorities.add(
        const _OverviewPriority(
          label: AppStrings.overviewTightenLeaseAction,
          description: AppStrings.overviewLeaseWarning,
          navigateToFleet: false,
        ),
      );
    }
    if (riskyRoutes > 0) {
      priorities.add(
        const _OverviewPriority(
          label: AppStrings.overviewReviewPricingAction,
          description: AppStrings.overviewRouteWarning,
          navigateToFleet: false,
        ),
      );
    }
    if (runwayDays != null && runwayDays < 45) {
      priorities.add(
        const _OverviewPriority(
          label: AppStrings.overviewAssignFleetAction,
          description: AppStrings.overviewRunwayWarning,
          navigateToFleet: false,
        ),
      );
    }
    if (operationalStatus == 'Recovery') {
      priorities.add(
        const _OverviewPriority(
          label: AppStrings.overviewProtectRecoveryAction,
          description: AppStrings.overviewRecoveryWarning,
          navigateToFleet: false,
        ),
      );
    }
    if (leaderGap != null && leaderGap > 5000000) {
      priorities.add(
        const _OverviewPriority(
          label: AppStrings.overviewExpandAction,
          description: AppStrings.overviewLeaderWarning,
          navigateToFleet: false,
        ),
      );
    }

    final burnMixLabel = finance == null || finance.totalExpense <= 0
        ? AppStrings.financeNoExpenseHistory
        : '${((finance.totalLease / finance.totalExpense) * 100).toStringAsFixed(0)}% lease / ${((finance.totalOperations / finance.totalExpense) * 100).toStringAsFixed(0)}% ops';

    return _OverviewSnapshot(
      totalFleetCount: fleet.length,
      readyFleetCount: readyFleet,
      groundedCount: grounded,
      leasedCount: leased,
      activeRoutes: routes.length,
      riskyRoutes: riskyRoutes,
      averageCondition: avgCondition,
      totalSlackHours: slackHours,
      averageFlightsPerRoute: avgFlightsPerRoute,
      leaseExposure: finance?.totalLease ?? 0.0,
      netYield: finance?.netProfit ?? 0.0,
      hasExpenseHistory: totalExpense > 0,
      revenueCoverageHealthy:
          finance == null || finance.totalRevenue >= totalExpense,
      runwayLabel: runwayLabel,
      runwayColor: runwayColor,
      leaderGapLabel: leaderGapLabel,
      leaderGapColor: leaderGapColor,
      avgFlightsPerRouteLabel: routes.isEmpty
          ? AppStrings.noRoutesCoverage
          : '${avgFlightsPerRoute.toStringAsFixed(1)}${AppStrings.perWeekSuffix}',
      burnMixLabel: burnMixLabel,
      operationalStatus: operationalStatus,
      operationalStatusColor: operationalStatusColor,
      consecutiveNegativeDays: user.consecutiveNegativeDays,
      recoveryStreakDays: user.recoveryStreakDays,
      leadingBotArchetype: botLeader?.archetype ?? AppStrings.loadingLabel,
      leadingBotStatus: botLeader?.status ?? AppStrings.loadingLabel,
      leadingBotFleet: botLeader?.fleetSize ?? 0,
      leadingBotRevenue: botLeader?.monthlyRevenue ?? 0.0,
      idleReadyFleetCount: idleReadyFleet,
      assignedFleetCount: assignedFleetCount,
      topRouteRiskLabel: topRiskRoute == null
          ? AppStrings.noRouteRiskLabel
          : '${topRiskRoute.originIata} ${AppStrings.routeDividerGlyph} ${topRiskRoute.destinationIata}',
      bestRouteYieldLabel: topYieldRoute == null
          ? AppStrings.noYieldSignalLabel
          : '${topYieldRoute.originIata} ${AppStrings.routeDividerGlyph} ${topYieldRoute.destinationIata}',
      priorities: priorities.take(3).toList(),
    );
  }
}
