// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/lazy_tab_cubit.dart';
import '../../../../core/utils/perf_debug.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/widgets/app_button.dart';
import '../../../../presentation/widgets/app_dialog_shell.dart';
import '../../../../presentation/widgets/app_info_strip.dart';
import '../../../../presentation/widgets/app_labeled_value.dart';
import '../../../../presentation/widgets/app_snackbar.dart';
import '../../../../presentation/widgets/app_stat_text.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../presentation/widgets/app_empty_state.dart';
import '../../../../presentation/widgets/app_table_icon_action.dart';
import '../../../../presentation/widgets/app_table_cells.dart';
import '../../../../presentation/widgets/app_table_shell.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/routes_cubit.dart';
import '../cubit/routes_state.dart';
import '../../domain/route_models.dart';
import '../../../fleet/domain/fleet_models.dart';
import '../widgets/blueprint_planner_form.dart';

class RoutesView extends StatefulWidget {
  const RoutesView({super.key});

  @override
  State<RoutesView> createState() => _RoutesViewState();
}

class _RoutesViewState extends State<RoutesView>
    with SingleTickerProviderStateMixin {
  static final _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 0,
  );
  late final TabController _tabController;
  late final LazyTabCubit _lazyTabCubit;

  @override
  void initState() {
    super.initState();
    _lazyTabCubit = LazyTabCubit();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final index = _tabController.index;
      if (!_lazyTabCubit.state.loadedIndexes.contains(index)) {
        PerfDebug.event('routes.tab_init', fields: {'tab': index});
      }
      PerfDebug.event('routes.tab_switch', fields: {'tab': index});
      _lazyTabCubit.activate(index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lazyTabCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Center(child: Text(AppStrings.unauthorized));
    }

    final userId = authState.user.id;
    final autoGroundingThreshold = authState.user.autoGroundingThreshold;
    return BlocProvider<LazyTabCubit>.value(
      value: _lazyTabCubit,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(
                  child: Text(
                    AppStrings.flightConnectionsTab,
                    style: AppTypography.sectionHeaderMedium,
                  ),
                ),
                Tab(
                  child: Text(
                    AppStrings.blueprintNetworkTab,
                    style: AppTypography.sectionHeaderMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.tabContentGap),
            Expanded(
              child: BlocBuilder<LazyTabCubit, LazyTabState>(
                builder: (context, tabState) {
                  return IndexedStack(
                    index: tabState.activeIndex,
                    children: [
                      RepaintBoundary(
                        child: tabState.loadedIndexes.contains(0)
                            ? _buildConnectionsTab(
                                userId,
                                _currencyFormat,
                                autoGroundingThreshold,
                              )
                            : const SizedBox.shrink(),
                      ),
                      RepaintBoundary(
                        child: tabState.loadedIndexes.contains(1)
                            ? _buildBlueprintTab(
                                userId,
                                _currencyFormat,
                                authState.user.autoGroundingThreshold,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FLIGHT CONNECTIONS TAB VIEW
  Widget _buildConnectionsTab(
    String userId,
    NumberFormat currencyFormat,
    double autoGroundingThreshold,
  ) {
    return BlocConsumer<RoutesCubit, RoutesState>(
      listener: (context, state) {
        if (state is RoutesActionSuccess) {
          AppSnackBar.showSuccess(context, state.message);
        } else if (state is RoutesError) {
          AppSnackBar.showError(context, state.message);
        }
      },
      buildWhen: (previous, current) => current is! RoutesActionSuccess,
      builder: (context, state) {
        if (state is RoutesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final routes = _getRoutes(state);
        final availableFleet = _getAvailableFleet(state);

        if (routes.isEmpty) {
          return _buildEmptyConnectionsView();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: RepaintBoundary(
                child: ResponsiveLayout(
                  desktopBody: _buildConnectionsTable(
                    context,
                    routes,
                    availableFleet,
                    userId,
                    currencyFormat,
                    autoGroundingThreshold,
                  ),
                  mobileBody: ListView.builder(
                    itemCount: routes.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildConnectionCard(
                        context,
                        routes[index],
                        availableFleet,
                        userId,
                        currencyFormat,
                        autoGroundingThreshold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyConnectionsView() {
    return const Center(
      child: AppEmptyState(
        icon: Icons.map_outlined,
        title: AppStrings.noActiveConnections,
        description: AppStrings.noActiveConnectionsDesc,
      ),
    );
  }

  Widget _buildConnectionsTable(
    BuildContext context,
    List<UserRoute> routes,
    List<UserFleetAircraft> availableFleet,
    String userId,
    NumberFormat currencyFormat,
    double autoGroundingThreshold,
  ) {
    return AppTableShell(
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(2.7), // ROUTE
          1: FlexColumnWidth(1.7), // PERFORMANCE
          2: FlexColumnWidth(2.2), // AIRCRAFT
          3: FlexColumnWidth(1.0), // ACTIONS
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: AppTheme.surfaceRaised,
            ),
            children: [
              _routesTableHeaderCell(AppStrings.routeHeader),
              _routesTableHeaderCell(AppStrings.networkPressureLabel),
              _routesTableHeaderCell(AppStrings.aircraftHeader),
              _routesTableHeaderCell(AppStrings.actionsHeader),
            ],
          ),
          ...routes.map((route) {
            final maintenance = route.buildMaintenancePreview(
              autoGroundingThreshold,
            );
            final idealPrice = route.baseTicketPrice;
            final pricingRatio = route.ticketPrice / idealPrice;

            Color priceColor;
            if (pricingRatio <= 1.0) {
              priceColor = AppTheme.success;
            } else if (pricingRatio <= 1.5) {
              priceColor = AppTheme.warning;
            } else {
              priceColor = AppTheme.error;
            }

            final hasAircraft = route.assignedAircraft != null;

            return TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.border, width: 1.0),
                ),
              ),
              children: [
                _routesTableCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIataBox(route.originIata),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            AppStrings.routeDividerGlyph,
                            style: AppTypography.badgeText.copyWith(
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _buildIataBox(route.destinationIata),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${route.origin.city} ${AppStrings.routeCitySeparator} ${route.destination.city}'
                            .toUpperCase(),
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTypography.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs - 2),
                      Text(
                        '${route.distanceKm.toStringAsFixed(0)} KM  •  ${route.flightsPerWeek} ${AppStrings.flightsPerWeekSuffix}',
                        style: AppTypography.captionLight.copyWith(
                          color: AppTypography.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _routesTableCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyFormat.format(route.ticketPrice),
                        style: AppTypography.badgeText.copyWith(
                          color: priceColor,
                          letterSpacing: 0.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs - 2),
                      Text(
                        '${AppStrings.maintenanceSlackLabel}: ${maintenance.maintenanceHoursPerWeek.toStringAsFixed(1)}H',
                        style: AppTypography.badgeText.copyWith(
                          color: maintenance.maintenanceHoursPerWeek > 0
                              ? AppTheme.info
                              : AppTypography.textSecondary,
                          letterSpacing: 0.0,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs - 2),
                      if (hasAircraft)
                        Text(
                          '${AppStrings.loadShortLabel} ${route.loadFactor.toStringAsFixed(1)}%',
                          style: AppTypography.badgeText.copyWith(
                            color: route.loadFactor >= 80.0
                                ? AppTheme.success
                                : (route.loadFactor >= 50.0
                                      ? AppTheme.warning
                                      : AppTheme.error),
                            letterSpacing: 0.0,
                          ),
                        )
                      else
                        Text(
                          AppStrings.groundedLabel,
                          style: AppTypography.badgeText.copyWith(
                            color: AppTheme.error,
                          ),
                        ),
                      Text(
                        '${AppStrings.demandLabel} ${route.demandMultiplier.toStringAsFixed(2)}${AppStrings.demandMultiplierSuffix}',
                        style: AppTypography.badgeText.copyWith(
                          color: AppTypography.textSecondary,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                ),
                _routesTableCell(
                  _buildAircraftDropdown(
                    context,
                    route,
                    availableFleet,
                    userId,
                  ),
                ),
                _routesTableCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTableIconAction(
                        tooltip: 'Route details',
                        icon: Icons.open_in_new,
                        onPressed: () => _showRouteDetailsDialog(
                          context,
                          route,
                          currencyFormat,
                          autoGroundingThreshold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AppTableIconAction(
                        tooltip: AppStrings.adjustRouteTooltip,
                        icon: Icons.tune,
                        onPressed: () => _showAdjustDialog(
                          context,
                          route,
                          userId,
                          currencyFormat,
                          context.read<AuthCubit>().state is AuthAuthenticated
                              ? (context.read<AuthCubit>().state
                                        as AuthAuthenticated)
                                    .user
                                    .autoGroundingThreshold
                              : GameConstants.defaultAutoGroundingThreshold,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AppTableIconAction(
                        tooltip: AppStrings.closeRouteTooltip,
                        icon: Icons.delete_forever_outlined,
                        color: AppTheme.error,
                        onPressed: () =>
                            _confirmCloseRoute(context, route, userId),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConnectionCard(
    BuildContext context,
    UserRoute route,
    List<UserFleetAircraft> availableFleet,
    String userId,
    NumberFormat currencyFormat,
    double autoGroundingThreshold,
  ) {
    final idealPrice = route.baseTicketPrice;
    final pricingRatio = route.ticketPrice / idealPrice;

    Color priceColor;
    final fareTooltipText = _buildFareTooltip(
      route: route,
      currencyFormat: currencyFormat,
      idealPrice: idealPrice,
      pricingRatio: pricingRatio,
    );
    if (pricingRatio <= 1.0) {
      priceColor = AppTheme.success;
    } else if (pricingRatio <= 1.5) {
      priceColor = AppTheme.warning;
    } else {
      priceColor = AppTheme.error;
    }

    final hasAircraft = route.assignedAircraft != null;
    final isGrounded =
        !hasAircraft ||
        route.assignedAircraft!.isMaintenanceGrounded(autoGroundingThreshold);
    final maintenance = route.buildMaintenancePreview(autoGroundingThreshold);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(
          color: isGrounded ? AppTheme.error : AppTheme.border,
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _buildIataBox(route.originIata),
                  const SizedBox(width: AppSpacing.sm - 2),
                  Text(
                    AppStrings.routeDividerGlyph,
                    style: AppTypography.badgeText.copyWith(
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm - 2),
                  _buildIataBox(route.destinationIata),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_forever_outlined,
                  color: AppTheme.error,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _confirmCloseRoute(context, route, userId),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm - 2),
          Text(
            '${route.origin.city} ${AppStrings.routeCitySeparator} ${route.destination.city}'
                .toUpperCase(),
            style: AppTypography.badgeText.copyWith(
              color: AppTypography.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Divider(color: AppTheme.border),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              _buildTycoonStatItem(
                context,
                AppStrings.distanceLabel,
                '${route.distanceKm.toStringAsFixed(0)} KM',
                AppStrings.distanceTooltip,
                icon: Icons.straighten,
              ),
              _buildTycoonStatItem(
                context,
                AppStrings.ticketFareLabel,
                currencyFormat.format(route.ticketPrice),
                fareTooltipText,
                valueColor: priceColor,
                icon: Icons.local_atm,
              ),
              _buildTycoonStatItem(
                context,
                AppStrings.frequencyLabel,
                '${route.flightsPerWeek}X/WK',
                AppStrings.frequencyTooltip,
                icon: Icons.calendar_today_outlined,
              ),
              _buildTycoonStatItem(
                context,
                AppStrings.maintenanceSlackLabel,
                '${maintenance.maintenanceHoursPerWeek.toStringAsFixed(1)}H',
                maintenance.isGrounded
                    ? AppStrings.maintenancePreviewGrounded
                    : '${AppStrings.maxScheduleLabel}: ${maintenance.maxFlightsPerWeek}${AppStrings.perWeekSuffix}',
                icon: Icons.build_circle_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (hasAircraft) ...[
            AppInfoStrip(
              backgroundColor: AppTheme.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.yieldMetrics,
                        style: AppTypography.badgeText.copyWith(
                          color: isGrounded
                              ? AppTheme.warning
                              : AppTheme.primary,
                        ),
                      ),
                      Text(
                        '${route.expectedPassengers} ${AppStrings.expectedPassengersLabel}',
                        style: AppTypography.badgeText.copyWith(
                          color: AppTheme.success,
                          letterSpacing: 0.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      AppStatText(
                        label: AppStrings.loadFactorLabel,
                        value: '${route.loadFactor.toStringAsFixed(1)}%',
                        valueColor: route.loadFactor >= 80.0
                            ? AppTheme.success
                            : (route.loadFactor >= 50.0
                                  ? AppTheme.warning
                                  : AppTheme.error),
                      ),
                      AppStatText(
                        label: AppStrings.askLabel,
                        value: NumberFormat.compact().format(route.weeklyASK),
                        valueColor: AppTypography.textPrimary,
                      ),
                      AppStatText(
                        label: AppStrings.rpkLabel,
                        value: NumberFormat.compact().format(route.weeklyRPK),
                        valueColor: AppTypography.textPrimary,
                      ),
                      AppStatText(
                        label: AppStrings.maintenanceImpactLabel,
                        value: maintenance.requiresAircraftAssignment
                            ? '--'
                            : '${maintenance.netHealthImpactPercent.toStringAsFixed(1)}%',
                        valueColor: maintenance.isGrounded
                            ? AppTheme.error
                            : (maintenance.netHealthImpactPercent > 0
                                  ? AppTheme.warning
                                  : AppTheme.success),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            AppInfoStrip(
              backgroundColor: AppTheme.error.withValues(alpha: 0.08),
              borderColor: AppTheme.error.withValues(alpha: 0.18),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.error,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      AppStrings.groundedAssignCarrier,
                      style: AppTypography.badgeText.copyWith(
                        color: AppTheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.carrierLabel,
                style: AppTypography.badgeText.copyWith(
                  color: AppTypography.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildAircraftDropdown(context, route, availableFleet, userId),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton(
            onPressed: () => _showRouteDetailsDialog(
              context,
              route,
              currencyFormat,
              autoGroundingThreshold,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              side: BorderSide(color: AppTheme.border),
            ),
            child: Text(
              'VIEW ROUTE DETAIL',
              style: AppTypography.badgeText.copyWith(color: AppTheme.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          OutlinedButton(
            onPressed: () => _showAdjustDialog(
              context,
              route,
              userId,
              currencyFormat,
              context.read<AuthCubit>().state is AuthAuthenticated
                  ? (context.read<AuthCubit>().state as AuthAuthenticated)
                        .user
                        .autoGroundingThreshold
                  : GameConstants.defaultAutoGroundingThreshold,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              side: BorderSide(color: AppTheme.border),
            ),
            child: Text(
              AppStrings.adjustParametersButton,
              style: AppTypography.badgeText.copyWith(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  // BLUEPRINT NETWORK TAB VIEW (Create Route Planner)
  Widget _buildBlueprintTab(
    String userId,
    NumberFormat currencyFormat,
    double autoGroundingThreshold,
  ) {
    return BlocBuilder<RoutesCubit, RoutesState>(
      buildWhen: (previous, current) => current is! RoutesActionSuccess,
      builder: (context, state) {
        if (state is RoutesLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final airports = _getAirports(state);
        return BlueprintPlannerForm(
          airports: airports,
          activeRoutes: _getRoutes(state),
          availableAircraft: _getAvailableFleet(state),
          userId: userId,
          autoGroundingThreshold: autoGroundingThreshold,
          currencyFormat: currencyFormat,
          routesCubit: context.read<RoutesCubit>(),
          onSuccessRedirect: () => _tabController.animateTo(0),
        );
      },
    );
  }

  // INTERACTIVE SCHEDULING DROPDOWN
  Widget _buildAircraftDropdown(
    BuildContext context,
    UserRoute route,
    List<UserFleetAircraft> availableFleet,
    String userId,
  ) {
    final activeId = route.assignedAircraftId;
    final cubit = context.read<RoutesCubit>();
    final compatibleFleet = availableFleet
        .where((fleet) => fleet.canOperateDistance(route.distanceKm))
        .toList();

    // Dropdown Items list contains unassigned fleet + the currently assigned aircraft
    final dropdownItems = <DropdownMenuItem<String?>>[
      DropdownMenuItem<String?>(
        value: null,
        child: Text(
          AppStrings.groundedNoneLabel,
          style: AppTypography.badgeText.copyWith(
            color: AppTheme.error,
            letterSpacing: 0.0,
          ),
        ),
      ),
    ];

    if (route.assignedAircraft != null) {
      dropdownItems.add(
        DropdownMenuItem<String?>(
          value: route.assignedAircraftId,
          child: Text(
            '${route.assignedAircraft!.model.manufacturer} ${route.assignedAircraft!.model.modelName} [${route.assignedAircraft!.tailNumber}]',
            style: AppTypography.badgeText.copyWith(
              color: AppTheme.primary,
              letterSpacing: 0.0,
            ),
          ),
        ),
      );
    }

    for (var fleet in compatibleFleet) {
      dropdownItems.add(
        DropdownMenuItem<String?>(
          value: fleet.id,
          child: Text(
            '${fleet.model.manufacturer} ${fleet.model.modelName} [${fleet.tailNumber}]',
            style: AppTypography.badgeText.copyWith(
              color: AppTypography.textPrimary,
              letterSpacing: 0.0,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md - 2),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border.all(color: AppTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: activeId,
          items: dropdownItems,
          onChanged: (newVal) async {
            await cubit.assignAircraft(
              routeId: route.id,
              aircraftId: newVal,
              userId: userId,
            );
          },
          dropdownColor: AppTheme.surface,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: AppTheme.primary, size: 18),
        ),
      ),
    );
  }

  // DIALOG CONFIRMATIONS

  void _showRouteDetailsDialog(
    BuildContext context,
    UserRoute route,
    NumberFormat currencyFormat,
    double autoGroundingThreshold,
  ) {
    final maintenance = route.buildMaintenancePreview(autoGroundingThreshold);
    final assessment = route.assignedAircraft == null
        ? null
        : UserRoute.buildPlanningAssessment(
            origin: route.origin,
            destination: route.destination,
            distanceKm: route.distanceKm,
            ticketPrice: route.ticketPrice,
            flightsPerWeek: route.flightsPerWeek,
            availableAircraft: [route.assignedAircraft!],
            autoGroundingThreshold: autoGroundingThreshold,
          );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AppDialogShell(
          title:
              '${route.originIata} ${AppStrings.routeDividerGlyph} ${route.destinationIata}',
          content: SizedBox(
            width: 560,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppLabeledValue(
                      label: AppStrings.distanceLabel,
                      value: '${route.distanceKm.toStringAsFixed(0)} KM',
                    ),
                    AppLabeledValue(
                      label: AppStrings.ticketFareLabel,
                      value: currencyFormat.format(route.ticketPrice),
                    ),
                    AppLabeledValue(
                      label: AppStrings.frequencyLabel,
                      value:
                          '${route.flightsPerWeek}${AppStrings.perWeekSuffix}',
                    ),
                    AppLabeledValue(
                      label: AppStrings.expectedPassengersLabel,
                      value: '${route.expectedPassengers}',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.lg,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppLabeledValue(
                      label: AppStrings.maintenanceSlackLabel,
                      value:
                          '${maintenance.maintenanceHoursPerWeek.toStringAsFixed(1)} H',
                      valueColor: maintenance.maintenanceHoursPerWeek > 0
                          ? AppTheme.info
                          : AppTypography.textPrimary,
                    ),
                    AppLabeledValue(
                      label: AppStrings.maintenanceImpactLabel,
                      value: maintenance.requiresAircraftAssignment
                          ? '--'
                          : '${maintenance.netHealthImpactPercent.toStringAsFixed(1)}%',
                      valueColor: maintenance.isGrounded
                          ? AppTheme.error
                          : (maintenance.netHealthImpactPercent > 0
                                ? AppTheme.warning
                                : AppTheme.success),
                    ),
                    AppLabeledValue(
                      label: AppStrings.askLabel,
                      value: NumberFormat.compact().format(route.weeklyASK),
                    ),
                    AppLabeledValue(
                      label: AppStrings.rpkLabel,
                      value: NumberFormat.compact().format(route.weeklyRPK),
                    ),
                  ],
                ),
                if (assessment != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppInfoStrip(
                    backgroundColor: AppTheme.background,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.routeViabilityBoard,
                          style: AppTypography.badgeText.copyWith(
                            color: AppTheme.primary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.lg,
                          runSpacing: AppSpacing.sm,
                          children: [
                            AppLabeledValue(
                              label: AppStrings.projectedRevenueLabel,
                              value: currencyFormat.format(
                                assessment.revenuePerFlight,
                              ),
                            ),
                            AppLabeledValue(
                              label: AppStrings.projectedDirectCostLabel,
                              value: currencyFormat.format(
                                assessment.directOperatingCostPerFlight,
                              ),
                            ),
                            AppLabeledValue(
                              label: AppStrings.projectedContributionLabel,
                              value: currencyFormat.format(
                                assessment.weeklyContribution,
                              ),
                              valueColor: assessment.weeklyContribution > 0
                                  ? AppTheme.success
                                  : AppTheme.error,
                            ),
                            AppLabeledValue(
                              label: AppStrings.bestFitAircraftLabel,
                              value:
                                  '${assessment.recommendedAircraft!.model.manufacturer} ${assessment.recommendedAircraft!.model.modelName}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAdjustDialog(
    BuildContext context,
    UserRoute route,
    String userId,
    NumberFormat currencyFormat,
    double autoGroundingThreshold,
  ) {
    final priceController = TextEditingController(
      text: route.ticketPrice.toStringAsFixed(0),
    );
    final routesCubit = context.read<RoutesCubit>();
    routesCubit.startAdjustmentMaintenancePreview(
      route: route,
      autoGroundingThreshold: autoGroundingThreshold,
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AppDialogShell(
          title: AppStrings.adjustConnectionParameters,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppStrings.routePricingGuidance}${currencyFormat.format(route.baseTicketPrice)}\n${AppStrings.routePricingGuidanceSuffix}',
                  style: AppTypography.captionRegular.copyWith(height: 1.4),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (route.assignedAircraft != null) ...[
                  _buildAdjustmentAssessmentCard(
                    route: route,
                    autoGroundingThreshold: autoGroundingThreshold,
                    currencyFormat: currencyFormat,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                TextField(
                  controller: priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: false,
                  ),
                  style: AppTypography.badgeText.copyWith(
                    color: AppTypography.textPrimary,
                    letterSpacing: 0.0,
                  ),
                  decoration: InputDecoration(
                    labelText: AppStrings.ticketPriceInputLabel,
                    labelStyle: AppTypography.captionRegular,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md - 2,
                      vertical: AppSpacing.md - 2,
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                BlocBuilder<RoutesCubit, RoutesState>(
                  bloc: routesCubit,
                  builder: (context, routesState) {
                    final preview = routesState is RoutesDataState
                        ? routesState.adjustmentMaintenancePreview
                        : null;
                    final sliderValue =
                        preview?.allocatedFlightsPerWeek.toDouble() ??
                        route.flightsPerWeek.toDouble();
                    final maxFlights =
                        preview?.maxFlightsPerWeek ??
                        route.getMaximumWeeklyFlights();
                    final effectiveMax = maxFlights > 0
                        ? maxFlights.toDouble()
                        : GameConstants.absoluteMaxWeeklyFlights.toDouble();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.weeklyFlightFrequencyLabel,
                          style: AppTypography.captionRegular,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            border: Border.all(color: AppTheme.border),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppStrings.weeklyFrequencyHint,
                                    style: AppTypography.captionRegular
                                        .copyWith(
                                          color: AppTypography.textSecondary,
                                        ),
                                  ),
                                  Text(
                                    '${sliderValue.round()}',
                                    style: AppTypography.buttonText.copyWith(
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: sliderValue.clamp(1, effectiveMax),
                                min: 1,
                                max: effectiveMax,
                                divisions: effectiveMax > 1
                                    ? effectiveMax.round() - 1
                                    : 1,
                                label: sliderValue.round().toString(),
                                onChanged: (value) {
                                  routesCubit
                                      .updateAdjustmentMaintenancePreview(
                                        route: route,
                                        flightsPerWeek: value.round(),
                                        autoGroundingThreshold:
                                            autoGroundingThreshold,
                                      );
                                },
                              ),
                              Text(
                                _buildAdjustmentMaintenanceCopy(
                                  preview,
                                  maxFlights,
                                ),
                                style: AppTypography.captionRegular.copyWith(
                                  color: AppTypography.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: Row(
            children: [
              Expanded(
                child: AppButton(
                  text: AppStrings.cancelLabel,
                  onPressed: () => Navigator.pop(dialogCtx),
                  type: AppButtonType.secondary,
                  height: 40,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  text: AppStrings.saveAdjustments,
                  onPressed: () async {
                    final priceText = priceController.text.trim();

                    final price = double.tryParse(priceText);
                    if (price == null || price <= 0) {
                      AppSnackBar.showError(
                        context,
                        AppStrings.invalidTicketPriceError,
                      );
                      return;
                    }

                    final preview = routesCubit.state is RoutesDataState
                        ? (routesCubit.state as RoutesDataState)
                              .adjustmentMaintenancePreview
                        : null;
                    final freq =
                        preview?.allocatedFlightsPerWeek ??
                        route.flightsPerWeek;

                    final maxFreq = route.getMaximumWeeklyFlights();
                    if (maxFreq > 0 && freq > maxFreq) {
                      AppSnackBar.showError(
                        context,
                        '${AppStrings.frequencyExceedsPhysicalLimitPrefix}$maxFreq${AppStrings.frequencyExceedsPhysicalLimitMiddle}${GameConstants.totalWeeklyHoursCap.toStringAsFixed(0)}${AppStrings.frequencyExceedsPhysicalLimitSuffix}',
                      );
                      return;
                    }

                    Navigator.pop(dialogCtx);
                    await routesCubit.updateRouteFrequencyAndPrice(
                      routeId: route.id,
                      ticketPrice: price,
                      flightsPerWeek: freq,
                      userId: userId,
                    );
                  },
                  height: 40,
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => routesCubit.clearAdjustmentMaintenancePreview());
  }

  String _buildAdjustmentMaintenanceCopy(
    RouteMaintenancePreview? preview,
    int maxFlights,
  ) {
    if (preview == null || preview.requiresAircraftAssignment) {
      final capLabel = maxFlights > 0 ? '$maxFlights' : 'N/A';
      return '${AppStrings.weeklyFrequencyHelperPrefix}$capLabel${AppStrings.weeklyFrequencyHelperSuffix} ${AppStrings.maintenancePreviewNeedsAssignment}';
    }

    if (preview.isGrounded) {
      return AppStrings.maintenancePreviewGrounded;
    }

    return '${AppStrings.maintenancePreviewPrefix}${preview.maintenanceHoursPerWeek.toStringAsFixed(1)}'
        '${AppStrings.maintenancePreviewMiddle}${preview.netHealthImpactPercent.toStringAsFixed(1)}%';
  }

  Widget _buildAdjustmentAssessmentCard({
    required UserRoute route,
    required double autoGroundingThreshold,
    required NumberFormat currencyFormat,
  }) {
    final assessment = UserRoute.buildPlanningAssessment(
      origin: route.origin,
      destination: route.destination,
      distanceKm: route.distanceKm,
      ticketPrice: route.ticketPrice,
      flightsPerWeek: route.flightsPerWeek,
      availableAircraft: route.assignedAircraft == null
          ? const []
          : [route.assignedAircraft!],
      autoGroundingThreshold: autoGroundingThreshold,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border.all(
          color: _viabilityColor(assessment.viability).withValues(alpha: 0.22),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.plannerAdjustmentBoard,
            style: AppTypography.badgeText.copyWith(
              color: _viabilityColor(assessment.viability),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatText(
                label: AppStrings.viableRouteLabel,
                value: _viabilityLabel(assessment.viability),
                valueColor: _viabilityColor(assessment.viability),
              ),
              AppStatText(
                label: AppStrings.projectedContributionLabel,
                value: currencyFormat.format(assessment.weeklyContribution),
                valueColor: assessment.weeklyContribution > 0
                    ? AppTheme.success
                    : AppTheme.error,
              ),
              AppStatText(
                label: AppStrings.targetScheduleCapLabel,
                value:
                    '${assessment.weeklyFlights}/${assessment.maxWeeklyFlights > 0 ? assessment.maxWeeklyFlights : GameConstants.absoluteMaxWeeklyFlights}${AppStrings.perWeekSuffix}',
                valueColor:
                    assessment.maxWeeklyFlights > 0 &&
                        assessment.weeklyFlights >=
                            (assessment.maxWeeklyFlights * 0.9)
                    ? AppTheme.warning
                    : AppTypography.textPrimary,
              ),
              AppStatText(
                label: AppStrings.maintenanceImpactLabel,
                value: '${assessment.netWearPerWeek.toStringAsFixed(1)}%',
                valueColor: assessment.netWearPerWeek > 0
                    ? AppTheme.warning
                    : AppTheme.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmCloseRoute(
    BuildContext context,
    UserRoute route,
    String userId,
  ) {
    final routesCubit = context.read<RoutesCubit>();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AppDialogShell(
          title: AppStrings.closeActiveConnection,
          titleColor: AppTheme.error,
          content: Text(
            '${AppStrings.closeRouteConfirmPrefix}${route.originIata}${AppStrings.closeRouteConfirmMiddle}${route.destinationIata}${AppStrings.closeRouteConfirmSuffix}',
            style: AppTypography.captionRegular.copyWith(
              color: AppTypography.textPrimary,
              height: 1.4,
            ),
          ),
          actions: Row(
            children: [
              Expanded(
                child: AppButton(
                  text: AppStrings.cancelLabel,
                  onPressed: () => Navigator.pop(dialogCtx),
                  type: AppButtonType.secondary,
                  height: 40,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  text: AppStrings.deleteRoute,
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    await routesCubit.deleteRoute(
                      routeId: route.id,
                      userId: userId,
                    );
                  },
                  height: 40,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // WIDGET HELPERS

  Widget _buildIataBox(String iata) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.15),
        border: Border.all(color: AppTheme.primary, width: 1.0),
      ),
      child: Text(
        iata,
        style: AppTypography.badgeText.copyWith(
          color: AppTheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTycoonStatItem(
    BuildContext context,
    String label,
    String value,
    String tooltipMessage, {
    Color? valueColor,
    IconData? icon,
  }) {
    return Tooltip(
      message: tooltipMessage,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      textStyle: AppTypography.badgeText.copyWith(
        color: AppTypography.textPrimary,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: valueColor ?? AppTheme.textSecondary),
            const SizedBox(width: AppSpacing.xs),
          ],
          AppStatText(
            label: label,
            value: value,
            labelColor: AppTheme.textSecondary,
            valueColor: valueColor ?? AppTypography.textPrimary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Icon(Icons.info_outline, size: 11, color: AppTheme.textMuted),
        ],
      ),
    );
  }

  // RECOVERY DATAS

  List<UserRoute> _getRoutes(RoutesState state) {
    if (state is RoutesDataState) return state.routes;
    return [];
  }

  List<Airport> _getAirports(RoutesState state) {
    if (state is RoutesDataState) return state.airports;
    return [];
  }

  List<UserFleetAircraft> _getAvailableFleet(RoutesState state) {
    if (state is RoutesDataState) return state.availableAircraft;
    return [];
  }

  Widget _routesTableHeaderCell(String label) {
    return AppTableHeaderCell(
      label: label,
      color: AppTypography.textSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }

  Widget _routesTableCell(Widget child) {
    return AppTableBodyCell(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: child,
    );
  }

  String _buildFareTooltip({
    required UserRoute route,
    required NumberFormat currencyFormat,
    required double idealPrice,
    required double pricingRatio,
  }) {
    if (pricingRatio <= 1.0) {
      return '${AppStrings.routePricingWatchStrong} (${route.demandMultiplier.toStringAsFixed(2)}x)';
    }
    if (pricingRatio <= 1.5) {
      return '${AppStrings.elasticityCalibratedDesc} (${route.demandMultiplier.toStringAsFixed(2)}x)';
    }
    return '${AppStrings.routePricingWatchWeak} ${currencyFormat.format(idealPrice)}';
  }

  Color _viabilityColor(RouteViabilityBand viability) {
    switch (viability) {
      case RouteViabilityBand.strong:
        return AppTheme.success;
      case RouteViabilityBand.workable:
        return AppTheme.warning;
      case RouteViabilityBand.weak:
        return AppTheme.error;
      case RouteViabilityBand.blocked:
        return AppTheme.error;
    }
  }

  String _viabilityLabel(RouteViabilityBand viability) {
    switch (viability) {
      case RouteViabilityBand.strong:
        return AppStrings.viabilityStrongLabel;
      case RouteViabilityBand.workable:
        return AppStrings.viabilityWorkableLabel;
      case RouteViabilityBand.weak:
        return AppStrings.viabilityWeakLabel;
      case RouteViabilityBand.blocked:
        return AppStrings.viabilityBlockedLabel;
    }
  }
}
