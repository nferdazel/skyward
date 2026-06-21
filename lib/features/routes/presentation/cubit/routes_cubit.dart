// ignore_for_file: avoid_print
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../../core/database/supabase_client.dart';
import '../../../../core/mixins/simulation_reactive_mixin.dart';
import '../../../../core/realtime/realtime_subscription_bag.dart';
import '../../../../core/utils/dev_mode_manager.dart';
import '../../../../core/utils/perf_debug.dart';
import '../../../fleet/domain/fleet_models.dart';
import '../../../simulation/presentation/cubit/simulation_cubit.dart';
import '../../domain/route_models.dart';
import 'routes_state.dart';

class RoutesCubit extends Cubit<RoutesState> with SimulationReactiveMixin {
  List<UserRoute> _cachedRoutes = [];
  List<Airport> _cachedAirports = [];
  List<UserFleetAircraft> _cachedAvailableAircraft = [];
  RouteMaintenancePreview? _plannerMaintenancePreview;
  RouteMaintenancePreview? _adjustmentMaintenancePreview;
  double _effectiveGroundingThreshold =
      GameConstants.defaultAutoGroundingThreshold;
  final RealtimeSubscriptionBag _realtimeSubscriptions =
      RealtimeSubscriptionBag();
  Timer? _realtimeRefreshDebounce;
  Future<void>? _activeLoad;

  RoutesCubit() : super(const RoutesInitial());

  RoutesDataState _snapshotState() {
    return RoutesLoaded(
      routes: List<UserRoute>.from(_cachedRoutes),
      airports: List<Airport>.from(_cachedAirports),
      availableAircraft: List<UserFleetAircraft>.from(_cachedAvailableAircraft),
      plannerMaintenancePreview: _plannerMaintenancePreview,
      adjustmentMaintenancePreview: _adjustmentMaintenancePreview,
    );
  }

  void _emitLoaded() {
    emit(
      RoutesLoaded(
        routes: List<UserRoute>.from(_cachedRoutes),
        airports: List<Airport>.from(_cachedAirports),
        availableAircraft: List<UserFleetAircraft>.from(
          _cachedAvailableAircraft,
        ),
        plannerMaintenancePreview: _plannerMaintenancePreview,
        adjustmentMaintenancePreview: _adjustmentMaintenancePreview,
      ),
    );
  }

  void updatePlannerMaintenancePreview({
    required double distanceKm,
    int? flightsPerWeek,
    required double autoGroundingThreshold,
  }) {
    final currentFlights =
        flightsPerWeek ??
        _plannerMaintenancePreview?.allocatedFlightsPerWeek ??
        7;
    final nextPreview = UserRoute.buildMaintenancePreviewForSchedule(
      distanceKm: distanceKm,
      flightsPerWeek: currentFlights,
      aircraft: null,
      autoGroundingThreshold: autoGroundingThreshold,
    );
    if (_samePreview(_plannerMaintenancePreview, nextPreview)) {
      return;
    }
    _plannerMaintenancePreview = nextPreview;
    if (state is RoutesDataState) {
      _emitLoaded();
    }
  }

  void clearPlannerMaintenancePreview() {
    if (_plannerMaintenancePreview == null) {
      return;
    }
    _plannerMaintenancePreview = null;
    if (state is RoutesDataState) {
      _emitLoaded();
    }
  }

  bool _samePreview(
    RouteMaintenancePreview? left,
    RouteMaintenancePreview? right,
  ) {
    if (identical(left, right)) return true;
    if (left == null || right == null) return false;
    return left.allocatedFlightsPerWeek == right.allocatedFlightsPerWeek &&
        left.maxFlightsPerWeek == right.maxFlightsPerWeek &&
        left.maintenanceHoursPerWeek == right.maintenanceHoursPerWeek &&
        left.grossDamagePercent == right.grossDamagePercent &&
        left.selfHealingCreditPercent == right.selfHealingCreditPercent &&
        left.netHealthImpactPercent == right.netHealthImpactPercent &&
        left.isGrounded == right.isGrounded &&
        left.requiresAircraftAssignment == right.requiresAircraftAssignment;
  }

  void startAdjustmentMaintenancePreview({
    required UserRoute route,
    required double autoGroundingThreshold,
  }) {
    _adjustmentMaintenancePreview =
        UserRoute.buildMaintenancePreviewForSchedule(
          distanceKm: route.distanceKm,
          flightsPerWeek: route.flightsPerWeek,
          aircraft: route.assignedAircraft,
          autoGroundingThreshold: autoGroundingThreshold,
        );
    if (state is RoutesDataState) {
      _emitLoaded();
    }
  }

  void updateAdjustmentMaintenancePreview({
    required UserRoute route,
    required int flightsPerWeek,
    required double autoGroundingThreshold,
  }) {
    _adjustmentMaintenancePreview =
        UserRoute.buildMaintenancePreviewForSchedule(
          distanceKm: route.distanceKm,
          flightsPerWeek: flightsPerWeek,
          aircraft: route.assignedAircraft,
          autoGroundingThreshold: autoGroundingThreshold,
        );
    if (state is RoutesDataState) {
      _emitLoaded();
    }
  }

  void clearAdjustmentMaintenancePreview() {
    _adjustmentMaintenancePreview = null;
    if (state is RoutesDataState) {
      _emitLoaded();
    }
  }

  void setupReactivity(SimulationCubit simCubit, String userId) {
    subscribeToSimulation(
      simCubit,
      () => loadRoutesAndData(userId, silent: true),
      delay: const Duration(milliseconds: 400),
    );
    _setupRealtime(userId);
  }

  @override
  Future<void> close() async {
    disposeReactivity();
    _realtimeRefreshDebounce?.cancel();
    await _realtimeSubscriptions.clear();
    return super.close();
  }

  // Load routes, airports catalog, and available (unassigned) aircraft
  Future<void> loadRoutesAndData(String userId, {bool silent = false}) async {
    if (_activeLoad != null) {
      await _activeLoad;
      return;
    }
    _activeLoad = _loadRoutesAndDataInternal(userId, silent: silent);
    try {
      await _activeLoad;
    } finally {
      _activeLoad = null;
    }
  }

  Future<void> _loadRoutesAndDataInternal(
    String userId, {
    bool silent = false,
  }) async {
    final stopwatch = PerfDebug.start('routes.load');
    if (!silent) {
      emit(const RoutesLoading());
    }
    try {
      if (DevModeManager.isDevMode) {
        _devLoadMockData();
        return;
      }

      // 1. Fetch all airports
      final List<dynamic> airportsResponse = await SupabaseManager.client
          .from('airports')
          .select()
          .order('iata', ascending: true);

      final airports = airportsResponse.map((a) => Airport.fromMap(a)).toList();

      // 2. Fetch user's active routes, joining origin & destination airports plus assigned aircraft
      final List<dynamic> routesResponse = await SupabaseManager.client
          .from('user_routes')
          .select(
            '*, origin:airports!origin_iata(*), destination:airports!destination_iata(*), user_fleet(*, aircraft_models(*))',
          )
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final routes = routesResponse.map((r) => UserRoute.fromMap(r)).toList();

      final userThresholdRecord = await SupabaseManager.client
          .from('users')
          .select('auto_grounding_threshold')
          .eq('id', userId)
          .single();
      final userThreshold =
          (userThresholdRecord['auto_grounding_threshold'] as num?)
              ?.toDouble() ??
          GameConstants.defaultAutoGroundingThreshold;
      _effectiveGroundingThreshold =
          userThreshold > GameConstants.absoluteMinimumSafetyLimit
          ? userThreshold
          : GameConstants.absoluteMinimumSafetyLimit;

      // 3. Fetch user's active fleet aircraft to filter unassigned ones
      final List<dynamic> fleetResponse = await SupabaseManager.client
          .from('user_fleet')
          .select('*, aircraft_models(*)')
          .eq('user_id', userId);

      final allFleet = fleetResponse
          .map((f) => UserFleetAircraft.fromMap(f))
          .toList();

      // Filter out aircraft already assigned to other routes to prevent double-scheduling exploits
      final assignedAircraftIds = routes
          .map((r) => r.assignedAircraftId)
          .whereType<String>()
          .toSet();

      final availableAircraft = allFleet
          .where(
            (f) =>
                !assignedAircraftIds.contains(f.id) &&
                !f.isMaintenanceGrounded(_effectiveGroundingThreshold),
          )
          .toList();

      _cachedRoutes = routes;
      _cachedAirports = airports;
      _cachedAvailableAircraft = availableAircraft;
      PerfDebug.end(
        'routes.load',
        stopwatch,
        fields: {
          'silent': silent,
          'airports': airports.length,
          'routes': routes.length,
          'availableFleet': availableAircraft.length,
        },
      );

      emit(
        RoutesLoaded(
          routes: routes,
          airports: airports,
          availableAircraft: availableAircraft,
          plannerMaintenancePreview: _plannerMaintenancePreview,
          adjustmentMaintenancePreview: _adjustmentMaintenancePreview,
        ),
      );
    } catch (e, stack) {
      PerfDebug.end(
        'routes.load',
        stopwatch,
        fields: {'silent': silent, 'error': true},
      );
      SupabaseManager.logError('loadRoutesAndData', e, stack);
      emit(
        RoutesError(
          message: 'Failed to load routes: ${e.toString()}',
          hasData: _cachedRoutes.isNotEmpty || _cachedAirports.isNotEmpty,
          routes: List<UserRoute>.from(_cachedRoutes),
          airports: List<Airport>.from(_cachedAirports),
          availableAircraft: List<UserFleetAircraft>.from(
            _cachedAvailableAircraft,
          ),
          plannerMaintenancePreview: _plannerMaintenancePreview,
          adjustmentMaintenancePreview: _adjustmentMaintenancePreview,
        ),
      );
    }
  }

  void _scheduleRealtimeRefresh(String userId) {
    PerfDebug.event(
      'routes.realtime_refresh_scheduled',
      fields: {'user': userId},
    );
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 180), () {
      unawaited(loadRoutesAndData(userId, silent: true));
    });
  }

  // Create a new flight connection route
  Future<bool> createRoute({
    required String userId,
    required String originIata,
    required String destinationIata,
    required double distanceKm,
    required double ticketPrice,
    required int flightsPerWeek,
  }) async {
    final snapshot = _snapshotState();
    emit(
      RoutesActionLoading(
        routes: snapshot.routes,
        airports: snapshot.airports,
        availableAircraft: snapshot.availableAircraft,
        plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
        adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
      ),
    );
    try {
      if (DevModeManager.isDevMode) {
        // Dev Fallback Route Insertion
        final origin = _cachedAirports.firstWhere((a) => a.iata == originIata);
        final dest = _cachedAirports.firstWhere(
          (a) => a.iata == destinationIata,
        );
        final newRoute = UserRoute(
          id: 'mock-route-${DateTime.now().millisecondsSinceEpoch}',
          originIata: originIata,
          destinationIata: destinationIata,
          distanceKm: distanceKm,
          ticketPrice: ticketPrice,
          flightsPerWeek: flightsPerWeek,
          origin: origin,
          destination: dest,
        );
        _cachedRoutes.insert(0, newRoute);
        emit(
          RoutesActionSuccess(
            message: 'Route established successfully!',
            routes: List<UserRoute>.from(_cachedRoutes),
            airports: List<Airport>.from(_cachedAirports),
            availableAircraft: List<UserFleetAircraft>.from(
              _cachedAvailableAircraft,
            ),
            plannerMaintenancePreview: _plannerMaintenancePreview,
            adjustmentMaintenancePreview: _adjustmentMaintenancePreview,
          ),
        );
        _emitLoaded();
        return true;
      }

      final List<dynamic> response = await SupabaseManager.client.rpc(
        'create_route',
        params: {
          'p_origin_iata': originIata,
          'p_destination_iata': destinationIata,
          'p_distance_km': distanceKm,
          'p_ticket_price': ticketPrice,
          'p_flights_per_week': flightsPerWeek,
        },
      );

      final result = response.isNotEmpty
          ? response[0] as Map<String, dynamic>
          : <String, dynamic>{};
      final success = result['success'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Route creation failed.';
      if (!success) {
        SupabaseManager.logRpcFailure('create_route', {
          'p_user_id': userId,
          'p_origin_iata': originIata,
          'p_destination_iata': destinationIata,
        }, message);
        emit(
          RoutesError(
            message: message,
            hasData: true,
            routes: snapshot.routes,
            airports: snapshot.airports,
            availableAircraft: snapshot.availableAircraft,
            plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
            adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
          ),
        );
        _emitLoaded();
        return false;
      }

      emit(
        RoutesActionSuccess(
          message: message,
          routes: snapshot.routes,
          airports: snapshot.airports,
          availableAircraft: snapshot.availableAircraft,
          plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
          adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
        ),
      );
      await loadRoutesAndData(userId, silent: true);
      return true;
    } catch (e, stack) {
      SupabaseManager.logError('createRoute', e, stack);
      emit(
        RoutesError(
          message: e.toString(),
          hasData: true,
          routes: snapshot.routes,
          airports: snapshot.airports,
          availableAircraft: snapshot.availableAircraft,
          plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
          adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
        ),
      );
      _emitLoaded();
      return false;
    }
  }

  // Assign or unassign aircraft to a route
  Future<bool> assignAircraft({
    required String routeId,
    required String? aircraftId,
    required String userId,
  }) async {
    final snapshot = _snapshotState();
    emit(
      RoutesActionLoading(
        routes: snapshot.routes,
        airports: snapshot.airports,
        availableAircraft: snapshot.availableAircraft,
        plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
        adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
      ),
    );
    try {
      if (DevModeManager.isDevMode) {
        // Dev Fallback
        final routeIdx = _cachedRoutes.indexWhere((r) => r.id == routeId);
        if (routeIdx != -1) {
          final target = _cachedRoutes[routeIdx];
          UserFleetAircraft? assigned;
          if (aircraftId != null) {
            final fleetIdx = _cachedAvailableAircraft.indexWhere(
              (f) => f.id == aircraftId,
            );
            if (fleetIdx != -1) {
              assigned = _cachedAvailableAircraft.removeAt(fleetIdx);
            }
          }

          // If unassigning, add back to available
          if (aircraftId == null && target.assignedAircraft != null) {
            _cachedAvailableAircraft.add(target.assignedAircraft!);
          }

          _cachedRoutes[routeIdx] = UserRoute(
            id: target.id,
            originIata: target.originIata,
            destinationIata: target.destinationIata,
            distanceKm: target.distanceKm,
            ticketPrice: target.ticketPrice,
            flightsPerWeek: target.flightsPerWeek,
            origin: target.origin,
            destination: target.destination,
            assignedAircraftId: aircraftId,
            assignedAircraft: assigned,
          );
        }
        emit(
          RoutesActionSuccess(
            message: 'Aircraft assignment updated!',
            routes: List<UserRoute>.from(_cachedRoutes),
            airports: List<Airport>.from(_cachedAirports),
            availableAircraft: List<UserFleetAircraft>.from(
              _cachedAvailableAircraft,
            ),
            plannerMaintenancePreview: _plannerMaintenancePreview,
            adjustmentMaintenancePreview: _adjustmentMaintenancePreview,
          ),
        );
        _emitLoaded();
        return true;
      }

      final List<dynamic> response = await SupabaseManager.client.rpc(
        'assign_aircraft_to_route',
        params: {
          'p_route_id': routeId,
          'p_aircraft_id': aircraftId,
        },
      );

      final result = response.isNotEmpty
          ? response[0] as Map<String, dynamic>
          : <String, dynamic>{};
      final success = result['success'] as bool? ?? false;
      final message =
          result['message'] as String? ?? 'Aircraft assignment failed.';
      if (!success) {
        SupabaseManager.logRpcFailure('assign_aircraft_to_route', {
          'p_user_id': userId,
          'p_route_id': routeId,
          'p_aircraft_id': aircraftId,
        }, message);
        emit(
          RoutesError(
            message: message,
            hasData: true,
            routes: snapshot.routes,
            airports: snapshot.airports,
            availableAircraft: snapshot.availableAircraft,
            plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
            adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
          ),
        );
        _emitLoaded();
        return false;
      }

      emit(
        RoutesActionSuccess(
          message: message,
          routes: snapshot.routes,
          airports: snapshot.airports,
          availableAircraft: snapshot.availableAircraft,
          plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
          adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
        ),
      );
      await loadRoutesAndData(userId, silent: true);
      return true;
    } catch (e, stack) {
      SupabaseManager.logError('assignAircraftToRoute', e, stack);
      emit(
        RoutesError(
          message: e.toString(),
          hasData: true,
          routes: snapshot.routes,
          airports: snapshot.airports,
          availableAircraft: snapshot.availableAircraft,
          plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
          adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
        ),
      );
      _emitLoaded();
      return false;
    }
  }

  // Update ticket price and weekly flight frequency
  Future<bool> updateRouteFrequencyAndPrice({
    required String routeId,
    required double ticketPrice,
    required int flightsPerWeek,
    required String userId,
  }) async {
    final snapshot = _snapshotState();
    emit(
      RoutesActionLoading(
        routes: snapshot.routes,
        airports: snapshot.airports,
        availableAircraft: snapshot.availableAircraft,
        plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
        adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
      ),
    );
    try {
      if (DevModeManager.isDevMode) {
        // Dev Fallback
        final idx = _cachedRoutes.indexWhere((r) => r.id == routeId);
        if (idx != -1) {
          final target = _cachedRoutes[idx];
          _cachedRoutes[idx] = UserRoute(
            id: target.id,
            originIata: target.originIata,
            destinationIata: target.destinationIata,
            distanceKm: target.distanceKm,
            ticketPrice: ticketPrice,
            flightsPerWeek: flightsPerWeek,
            origin: target.origin,
            destination: target.destination,
            assignedAircraftId: target.assignedAircraftId,
            assignedAircraft: target.assignedAircraft,
          );
        }
        emit(
          RoutesActionSuccess(
            message: 'Route frequency and pricing adjusted!',
            routes: List<UserRoute>.from(_cachedRoutes),
            airports: List<Airport>.from(_cachedAirports),
            availableAircraft: List<UserFleetAircraft>.from(
              _cachedAvailableAircraft,
            ),
            plannerMaintenancePreview: _plannerMaintenancePreview,
            adjustmentMaintenancePreview: _adjustmentMaintenancePreview,
          ),
        );
        _emitLoaded();
        return true;
      }

      final List<dynamic> response = await SupabaseManager.client.rpc(
        'update_route_frequency_and_price',
        params: {
          'p_route_id': routeId,
          'p_ticket_price': ticketPrice,
          'p_flights_per_week': flightsPerWeek,
        },
      );

      final result = response.isNotEmpty
          ? response[0] as Map<String, dynamic>
          : <String, dynamic>{};
      final success = result['success'] as bool? ?? false;
      final message =
          result['message'] as String? ??
          'Route frequency and pricing update failed.';
      if (!success) {
        SupabaseManager.logRpcFailure('update_route_frequency_and_price', {
          'p_user_id': userId,
          'p_route_id': routeId,
        }, message);
        emit(
          RoutesError(
            message: message,
            hasData: true,
            routes: snapshot.routes,
            airports: snapshot.airports,
            availableAircraft: snapshot.availableAircraft,
            plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
            adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
          ),
        );
        _emitLoaded();
        return false;
      }

      emit(
        RoutesActionSuccess(
          message: message,
          routes: snapshot.routes,
          airports: snapshot.airports,
          availableAircraft: snapshot.availableAircraft,
          plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
          adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
        ),
      );
      await loadRoutesAndData(userId, silent: true);
      return true;
    } catch (e, stack) {
      SupabaseManager.logError('updateRouteFrequencyAndPrice', e, stack);
      emit(
        RoutesError(
          message: e.toString(),
          hasData: true,
          routes: snapshot.routes,
          airports: snapshot.airports,
          availableAircraft: snapshot.availableAircraft,
          plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
          adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
        ),
      );
      _emitLoaded();
      return false;
    }
  }

  // Close/Delete a route
  Future<bool> deleteRoute({
    required String routeId,
    required String userId,
  }) async {
    final snapshot = _snapshotState();
    emit(
      RoutesActionLoading(
        routes: snapshot.routes,
        airports: snapshot.airports,
        availableAircraft: snapshot.availableAircraft,
        plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
        adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
      ),
    );
    try {
      if (DevModeManager.isDevMode) {
        // Dev Fallback Delete
        final idx = _cachedRoutes.indexWhere((r) => r.id == routeId);
        if (idx != -1) {
          final target = _cachedRoutes[idx];
          if (target.assignedAircraft != null) {
            _cachedAvailableAircraft.add(target.assignedAircraft!);
          }
          _cachedRoutes.removeAt(idx);
        }
        emit(
          RoutesActionSuccess(
            message: 'Route closed and aircraft grounded!',
            routes: List<UserRoute>.from(_cachedRoutes),
            airports: List<Airport>.from(_cachedAirports),
            availableAircraft: List<UserFleetAircraft>.from(
              _cachedAvailableAircraft,
            ),
            plannerMaintenancePreview: _plannerMaintenancePreview,
            adjustmentMaintenancePreview: _adjustmentMaintenancePreview,
          ),
        );
        _emitLoaded();
        return true;
      }

      final List<dynamic> response = await SupabaseManager.client.rpc(
        'delete_route',
        params: {'p_route_id': routeId},
      );

      final result = response.isNotEmpty
          ? response[0] as Map<String, dynamic>
          : <String, dynamic>{};
      final success = result['success'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Route deletion failed.';
      if (!success) {
        SupabaseManager.logRpcFailure('delete_route', {
          'p_user_id': userId,
          'p_route_id': routeId,
        }, message);
        emit(
          RoutesError(
            message: message,
            hasData: true,
            routes: snapshot.routes,
            airports: snapshot.airports,
            availableAircraft: snapshot.availableAircraft,
            plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
            adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
          ),
        );
        _emitLoaded();
        return false;
      }

      emit(
        RoutesActionSuccess(
          message: message,
          routes: snapshot.routes,
          airports: snapshot.airports,
          availableAircraft: snapshot.availableAircraft,
          plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
          adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
        ),
      );
      await loadRoutesAndData(userId, silent: true);
      return true;
    } catch (e, stack) {
      SupabaseManager.logError('deleteRoute', e, stack);
      emit(
        RoutesError(
          message: e.toString(),
          hasData: true,
          routes: snapshot.routes,
          airports: snapshot.airports,
          availableAircraft: snapshot.availableAircraft,
          plannerMaintenancePreview: snapshot.plannerMaintenancePreview,
          adjustmentMaintenancePreview: snapshot.adjustmentMaintenancePreview,
        ),
      );
      _emitLoaded();
      return false;
    }
  }

  // Seed Mock Data in Dev Mode
  void _devLoadMockData() {
    _cachedAirports = [
      Airport(
        iata: 'CGK',
        name: 'Soekarno-Hatta International',
        city: 'Jakarta',
        country: 'Indonesia',
        latitude: -6.1256,
        longitude: 106.6558,
        demandIndex: 95,
        airportTax: 1200.00,
      ),
      Airport(
        iata: 'SIN',
        name: 'Changi International',
        city: 'Singapore',
        country: 'Singapore',
        latitude: 1.3644,
        longitude: 103.9915,
        demandIndex: 98,
        airportTax: 1500.00,
      ),
      Airport(
        iata: 'KUL',
        name: 'Kuala Lumpur International',
        city: 'Kuala Lumpur',
        country: 'Malaysia',
        latitude: 2.7456,
        longitude: 101.7099,
        demandIndex: 90,
        airportTax: 1100.00,
      ),
      Airport(
        iata: 'BKK',
        name: 'Suvarnabhumi Airport',
        city: 'Bangkok',
        country: 'Thailand',
        latitude: 13.6900,
        longitude: 100.7501,
        demandIndex: 95,
        airportTax: 1250.00,
      ),
      Airport(
        iata: 'HND',
        name: 'Haneda Airport',
        city: 'Tokyo',
        country: 'Japan',
        latitude: 35.5494,
        longitude: 139.7798,
        demandIndex: 98,
        airportTax: 1400.00,
      ),
    ];

    final mockFleet = [
      UserFleetAircraft(
        id: 'mock-fleet-active-a320',
        nickname: 'Primary Eagle',
        acquisitionType: 'purchase',
        condition: 82.50,
        status: 'active',
        acquiredAt: DateTime.now(),
        model: AircraftModel(
          id: 'mock-a320',
          manufacturer: 'Airbus',
          modelName: 'A320neo',
          type: 'narrow_body_jet',
          rangeKm: 6500,
          capacity: 186,
          speedKmh: 833,
          fuelBurnPerKm: 4.16,
          maintenanceCostPerHour: 820.00,
          purchasePrice: 111000000.00,
          leasePricePerMonth: 550000.00,
        ),
      ),
      UserFleetAircraft(
        id: 'mock-fleet-active-atr72',
        nickname: 'Short-Haul Hopper',
        acquisitionType: 'lease',
        condition: 45.00,
        status: 'active',
        acquiredAt: DateTime.now(),
        model: AircraftModel(
          id: 'mock-atr72',
          manufacturer: 'ATR',
          modelName: 'ATR 72-600',
          type: 'regional_turboprop',
          rangeKm: 1500,
          capacity: 72,
          speedKmh: 510,
          fuelBurnPerKm: 2.5,
          maintenanceCostPerHour: 400.00,
          purchasePrice: 26000000.00,
          leasePricePerMonth: 130000.00,
        ),
      ),
    ];

    _cachedRoutes = [
      UserRoute(
        id: 'mock-route-1',
        originIata: 'CGK',
        destinationIata: 'SIN',
        distanceKm: 895.34,
        ticketPrice: 150.00,
        flightsPerWeek: 14,
        origin: _cachedAirports[0],
        destination: _cachedAirports[1],
        assignedAircraftId: 'mock-fleet-active-a320',
        assignedAircraft: mockFleet[0],
      ),
    ];

    _cachedAvailableAircraft = [mockFleet[1]];

    emit(
      RoutesLoaded(
        routes: _cachedRoutes,
        airports: _cachedAirports,
        availableAircraft: _cachedAvailableAircraft,
        plannerMaintenancePreview: _plannerMaintenancePreview,
        adjustmentMaintenancePreview: _adjustmentMaintenancePreview,
      ),
    );
  }

  void _setupRealtime(String userId) {
    if (DevModeManager.isDevMode || SupabaseManager.hasMockClient) return;
    unawaited(_realtimeSubscriptions.clear());

    final routesChannel = SupabaseManager.client
        .channel('public:user_routes:user_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_routes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _scheduleRealtimeRefresh(userId),
        )
        .subscribe();

    final fleetChannel = SupabaseManager.client
        .channel('public:user_fleet:routes-user_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_fleet',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) => _scheduleRealtimeRefresh(userId),
        )
        .subscribe();

    _realtimeSubscriptions
      ..add(routesChannel)
      ..add(fleetChannel);
  }
}
