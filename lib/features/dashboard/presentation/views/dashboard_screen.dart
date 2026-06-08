// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pulse_dot.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../core/widgets/ticker_tape.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../finance/presentation/cubit/finance_cubit.dart';
import '../../../finance/presentation/views/finance_view.dart';
import '../../../fleet/presentation/cubit/fleet_cubit.dart';
import '../../../fleet/presentation/views/fleet_view.dart';
import '../../../leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../../leaderboard/presentation/views/leaderboard_view.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';
import '../../../routes/presentation/cubit/routes_cubit.dart';
import '../../../routes/presentation/views/routes_view.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../settings/presentation/views/settings_view.dart';
import '../../../simulation/presentation/cubit/simulation_cubit.dart';
import '../../../simulation/presentation/cubit/simulation_state.dart';
import '../widgets/dashboard_sidebar.dart';
import '../widgets/top_hud.dart';
import 'overview_tab.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _AuthenticatedDashboardShell(
          key: ValueKey(authState.user.id),
          initialUser: authState.user,
        );
      },
    );
  }
}

class _AuthenticatedDashboardShell extends StatefulWidget {
  const _AuthenticatedDashboardShell({
    super.key,
    required this.initialUser,
  });

  final User initialUser;

  @override
  State<_AuthenticatedDashboardShell> createState() =>
      _AuthenticatedDashboardShellState();
}

class _AuthenticatedDashboardShellState
    extends State<_AuthenticatedDashboardShell> {
  static final _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );
  static final _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  late final NavigationCubit _navigationCubit;
  late final SimulationCubit _simulationCubit;
  late final FleetCubit _fleetCubit;
  late final RoutesCubit _routesCubit;
  late final LeaderboardCubit _leaderboardCubit;
  late final FinanceCubit _financeCubit;

  @override
  void initState() {
    super.initState();
    _navigationCubit = NavigationCubit();
    _simulationCubit = SimulationCubit();
    _fleetCubit = FleetCubit();
    _routesCubit = RoutesCubit();
    _leaderboardCubit = LeaderboardCubit();
    _financeCubit = FinanceCubit();
    _bootstrapForUser(widget.initialUser);
  }

  void _bootstrapForUser(User user) {
    _simulationCubit.startLoop(
      userId: user.id,
      initialGameTime: user.gameCurrentTime,
      initialCash: user.cashBalance,
      initialOperationalStatus: user.operationalStatus,
      initialConsecutiveNegativeDays: user.consecutiveNegativeDays,
      initialRecoveryStreakDays: user.recoveryStreakDays,
    );

    _fleetCubit
      ..loadFleetAndCatalog(user.id)
      ..setupReactivity(_simulationCubit, user.id);

    _routesCubit
      ..loadRoutesAndData(user.id)
      ..setupReactivity(_simulationCubit, user.id);

    _leaderboardCubit
      ..loadRankings(
        humanUserId: user.id,
        humanCompanyName: user.companyName,
        humanCeoName: user.ceoName,
        humanCash: user.cashBalance,
        humanNetWorth: 0.0,
        humanFleetSize: 0,
        humanMonthlyRevenue: 0.0,
      )
      ..setupReactivity(
        _simulationCubit,
        user.id,
        user.companyName,
        user.ceoName,
      );

    _financeCubit
      ..loadLedger(user.id)
      ..setupReactivity(_simulationCubit, user.id);
  }

  @override
  void dispose() {
    _navigationCubit.close();
    _simulationCubit.close();
    _fleetCubit.close();
    _routesCubit.close();
    _leaderboardCubit.close();
    _financeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationCubit>.value(value: _navigationCubit),
        BlocProvider<SimulationCubit>.value(value: _simulationCubit),
        BlocProvider<FleetCubit>.value(value: _fleetCubit),
        BlocProvider<RoutesCubit>.value(value: _routesCubit),
        BlocProvider<LeaderboardCubit>.value(value: _leaderboardCubit),
        BlocProvider<FinanceCubit>.value(value: _financeCubit),
      ],
      child: BlocListener<SimulationCubit, SimulationState>(
        listener: (context, simState) {
          final authState = context.read<AuthCubit>().state;
          if (authState is AuthAuthenticated) {
            final updatedUser = authState.user.copyWith(
              gameCurrentTime: simState.gameTime,
              cashBalance: simState.cashBalance,
              operationalStatus: simState.operationalStatus,
              consecutiveNegativeDays: simState.consecutiveNegativeDays,
              recoveryStreakDays: simState.recoveryStreakDays,
            );
            context.read<AuthCubit>().updateActiveUser(updatedUser);
          }
        },
        child: BlocBuilder<SimulationCubit, SimulationState>(
          builder: (context, simState) {
            return ResponsiveLayout(
              mobileBody: _buildMobileLayout(
                context,
                authState,
                simState,
                _currencyFormat,
                _dateFormat,
              ),
              desktopBody: _buildDesktopLayout(
                context,
                authState,
                simState,
                _currencyFormat,
                _dateFormat,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    AuthAuthenticated authState,
    SimulationState simState,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    final scale = context.watch<SettingsCubit>().state.uiScale;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          const TickerTape(),
          Expanded(
            child: Row(
              children: [
                DashboardSidebar(scale: scale),
                Expanded(
                  child: Column(
                    children: [
                      TopHud(
                        authState: authState,
                        simState: simState,
                        currencyFormat: currencyFormat,
                        dateFormat: dateFormat,
                        scale: scale,
                      ),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(
                            AppSpacing.pagePadding * scale,
                          ),
                          child: _buildActiveScreenContent(
                            context,
                            currencyFormat,
                            dateFormat,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AuthAuthenticated authState,
    SimulationState simState,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    final user = authState.user;
    const navItems = [
      AppStrings.dashboardOverview,
      AppStrings.dashboardHangar,
      AppStrings.dashboardRoutes,
      AppStrings.dashboardLedger,
      AppStrings.dashboardLeaderboard,
      AppStrings.dashboardSettings,
    ];
    const navIcons = [
      Icons.terminal,
      Icons.flight,
      Icons.map,
      Icons.receipt_long,
      Icons.emoji_events,
      Icons.settings,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              user.companyName,
              style: AppTypography.sectionHeaderMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${AppStrings.ceoPrefix}: ${user.ceoName.toUpperCase()}',
              style: AppTypography.badgeText.copyWith(
                letterSpacing: 0.8,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: AppTheme.error, size: 20),
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    PulseDot(
                      color: simState.isSyncing
                          ? AppTheme.warning
                          : AppTheme.success,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      dateFormat.format(simState.gameTime),
                      style: AppTypography.badgeText,
                    ),
                  ],
                ),
                Text(
                  'F: \$${simState.fuelPricePerLiter.toStringAsFixed(2)}/L',
                  style: AppTypography.badgeText.copyWith(
                    color: AppTheme.warning,
                    letterSpacing: 0.0,
                  ),
                ),
                Text(
                  currencyFormat.format(simState.cashBalance),
                  style: AppTypography.badgeText.copyWith(
                    color: AppTheme.success,
                    letterSpacing: 0.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: _buildActiveScreenContent(context, currencyFormat, dateFormat),
      ),
      bottomNavigationBar: BlocBuilder<NavigationCubit, NavigationState>(
        builder: (context, state) {
          return BottomNavigationBar(
            currentIndex: state.activeIndex,
            onTap: (index) => context.read<NavigationCubit>().selectTab(index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.surface,
            selectedItemColor: AppTheme.primary,
            unselectedItemColor: AppTheme.textSecondary,
            selectedLabelStyle: AppTypography.badgeText.copyWith(
              letterSpacing: 0.8,
            ),
            unselectedLabelStyle: AppTypography.badgeText.copyWith(
              letterSpacing: 0.6,
              fontWeight: FontWeight.normal,
            ),
            items: List.generate(
              navItems.length,
              (index) => BottomNavigationBarItem(
                icon: Icon(navIcons[index], size: 18),
                label: navItems[index],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveScreenContent(
    BuildContext context,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    final activeIndex = context.watch<NavigationCubit>().state.activeIndex;

    if (activeIndex == 0) {
      return OverviewTab(
        onNavigateToFleet: () => context.read<NavigationCubit>().selectTab(1),
        onNavigateToRoutes: () => context.read<NavigationCubit>().selectTab(2),
      );
    }
    if (activeIndex == 1) {
      return const FleetView();
    }
    if (activeIndex == 2) {
      return const RoutesView();
    }
    if (activeIndex == 3) {
      return const FinanceView();
    }
    if (activeIndex == 4) {
      return const LeaderboardView();
    }
    if (activeIndex == 5) {
      return const SettingsView();
    }
    return Container();
  }
}
