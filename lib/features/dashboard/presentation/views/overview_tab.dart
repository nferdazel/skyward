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
import '../../../fleet/presentation/cubit/fleet_cubit.dart';
import '../../../leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../../routes/presentation/cubit/routes_cubit.dart';
import '../../../simulation/presentation/cubit/simulation_cubit.dart';
import '../../../simulation/presentation/cubit/simulation_state.dart';
import '../../domain/overview_snapshot.dart';

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
    final simState = context.select((SimulationCubit cubit) => cubit.state);
    final overview = _selectOverviewSnapshot(context, user);
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
    );

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Region 1: Identity + Cash Band
          _buildIdentityCashBand(context, user, simState, currencyFormat, overview),
          const SizedBox(height: AppSpacing.sectionGap),
          // Region 2: Health KPIs + Risk Signals
          ResponsiveLayout(
            desktopBody: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildHealthKPIs(context, overview),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  flex: 2,
                  child: _buildRiskSignals(context, overview, currencyFormat),
                ),
              ],
            ),
            mobileBody: Column(
              children: [
                _buildHealthKPIs(context, overview),
                const SizedBox(height: AppSpacing.sectionGap),
                _buildRiskSignals(context, overview, currencyFormat),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          // Region 3: Quick Actions
          _buildQuickActions(context),
        ],
      ),
    );
  }

  // Region 1: Identity + Cash Band
  Widget _buildIdentityCashBand(
    BuildContext context,
    dynamic user,
    SimulationState simState,
    NumberFormat currencyFormat,
    OverviewSnapshot overview,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Company identity
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.companyName, style: AppTypography.screenTitleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${AppStrings.ceoPrefix}: ${user.ceoName}',
                  style: AppTypography.captionRegular.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Operational status chip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: overview.operationalStatusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: overview.operationalStatusColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              overview.operationalStatus.toUpperCase(),
              style: AppTypography.microLabel.copyWith(
                color: overview.operationalStatusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          // Cash position
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'CASH POSITION',
                style: AppTypography.microLabel.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                currencyFormat.format(simState.cashBalance),
                style: AppTypography.largeKpi.copyWith(
                  color: AppTheme.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Region 2 Left: Operational Health KPIs
  Widget _buildHealthKPIs(BuildContext context, OverviewSnapshot overview) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('OPERATIONAL HEALTH'),
        const SizedBox(height: AppSpacing.md),
        _buildKPIRow([
          _buildKPICard(
            'FLEET READY',
            '${overview.readyFleetCount}/${overview.totalFleetCount}',
            AppTheme.success,
          ),
          _buildKPICard(
            'AVG CONDITION',
            '${overview.averageCondition.toStringAsFixed(1)}%',
            overview.averageCondition >= 70 ? AppTheme.success : AppTheme.warning,
          ),
          _buildKPICard(
            'WEEKLY SLACK',
            '${overview.totalSlackHours.toStringAsFixed(1)}h',
            AppTheme.info,
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        _buildKPIRow([
          _buildKPICard(
            'ACTIVE ROUTES',
            '${overview.activeRoutes}',
            AppTheme.primary,
          ),
          _buildKPICard(
            'NETWORK PRESSURE',
            '${overview.riskyRoutes}/${overview.activeRoutes}',
            overview.riskyRoutes > 0 ? AppTheme.warning : AppTheme.success,
          ),
          _buildKPICard(
            'RUNWAY',
            overview.runwayLabel,
            overview.runwayColor,
          ),
        ]),
      ],
    );
  }

  // Region 2 Right: Risk & Competitive Signals
  Widget _buildRiskSignals(
    BuildContext context,
    OverviewSnapshot overview,
    NumberFormat currencyFormat,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('RISK & COMPETITIVE SIGNALS'),
        const SizedBox(height: AppSpacing.md),
        _buildSignalItem(
          'COMPETITIVE GAP',
          overview.leaderGapLabel,
          overview.leaderGapColor,
        ),
        _buildSignalItem(
          'TOP ROUTE RISK',
          overview.topRouteRiskLabel,
          AppTheme.warning,
        ),
        _buildSignalItem(
          'NET YIELD',
          currencyFormat.format(overview.netYield),
          overview.netYield >= 0 ? AppTheme.success : AppTheme.error,
        ),
        _buildSignalItem(
          'IDLE FLEET',
          '${overview.idleReadyFleetCount} airframes',
          overview.idleReadyFleetCount > 0 ? AppTheme.warning : AppTheme.success,
        ),
      ],
    );
  }

  // Region 3: Quick Actions
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            'Manage Fleet',
            'View and manage your aircraft',
            onNavigateToFleet,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildActionButton(
            context,
            'Manage Routes',
            'Plan and optimize your network',
            onNavigateToRoutes,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTypography.sectionHeaderMedium.copyWith(
        letterSpacing: 0.08,
      ),
    );
  }

  Widget _buildKPIRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .expand((child) => [Expanded(child: child), const SizedBox(width: AppSpacing.md)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _buildKPICard(String label, String value, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.microLabel.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.dataEmphasis.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.microLabel.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    value,
                    style: AppTypography.hudValue.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
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
      borderRadius: BorderRadius.circular(4),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    description,
                    style: AppTypography.captionRegular.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_right_alt, color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  OverviewSnapshot _selectOverviewSnapshot(BuildContext context, dynamic user) {
    final simState = context.select((SimulationCubit cubit) => cubit.state);
    final fleetState = context.select((FleetCubit cubit) => cubit.state);
    final routesState = context.select((RoutesCubit cubit) => cubit.state);
    final financeState = context.select((FinanceCubit cubit) => cubit.state);
    final leaderboardState = context.select(
      (LeaderboardCubit cubit) => cubit.state,
    );

    return OverviewSnapshot.fromStates(
      user: user,
      simState: simState,
      fleetState: fleetState,
      routesState: routesState,
      financeState: financeState,
      leaderboardState: leaderboardState,
    );
  }
}
