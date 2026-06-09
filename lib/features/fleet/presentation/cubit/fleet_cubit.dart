// ignore_for_file: avoid_print
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/supabase_client.dart';
import '../../../../core/mixins/simulation_reactive_mixin.dart';
import '../../../../core/realtime/realtime_subscription_bag.dart';
import '../../../../core/utils/dev_mode_manager.dart';
import '../../../../core/utils/perf_debug.dart';
import '../../domain/fleet_models.dart';
import 'fleet_state.dart';

typedef FleetBalanceCallback = FutureOr<void> Function(double newCashBalance);

class FleetCubit extends Cubit<FleetState> with SimulationReactiveMixin {
  // Local cache to maintain state during action loads
  List<UserFleetAircraft> _cachedFleet = [];
  List<AircraftModel> _cachedCatalog = [];
  List<String> _selectedManufacturers = [];
  List<String> _selectedCategories = [];
  List<String> _selectedRangeBrackets = [];
  String _sortBy = 'price_asc';
  final RealtimeSubscriptionBag _realtimeSubscriptions =
      RealtimeSubscriptionBag();
  bool _suppressNextFleetRealtimeReload = false;
  Timer? _realtimeRefreshDebounce;
  Future<void>? _activeLoad;

  FleetCubit() : super(const FleetInitial());

  FleetDataState _snapshotState() {
    return FleetLoaded(
      fleet: List<UserFleetAircraft>.from(_cachedFleet),
      catalog: List<AircraftModel>.from(_cachedCatalog),
      selectedManufacturers: List<String>.from(_selectedManufacturers),
      selectedCategories: List<String>.from(_selectedCategories),
      selectedRangeBrackets: List<String>.from(_selectedRangeBrackets),
      sortBy: _sortBy,
    );
  }

  void _emitLoaded() {
    emit(
      FleetLoaded(
        fleet: _cachedFleet,
        catalog: _cachedCatalog,
        selectedManufacturers: _selectedManufacturers,
        selectedCategories: _selectedCategories,
        selectedRangeBrackets: _selectedRangeBrackets,
        sortBy: _sortBy,
      ),
    );
  }

  void setupReactivity(dynamic simCubit, String userId) {
    subscribeToSimulation(
      simCubit,
      () => loadFleetAndCatalog(userId, silent: true),
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

  // Load available aircraft catalog and user owned/leased fleet
  Future<void> loadFleetAndCatalog(String userId, {bool silent = false}) async {
    if (_activeLoad != null) {
      await _activeLoad;
      return;
    }
    _activeLoad = _loadFleetAndCatalogInternal(userId, silent: silent);
    try {
      await _activeLoad;
    } finally {
      _activeLoad = null;
    }
  }

  Future<void> _loadFleetAndCatalogInternal(
    String userId, {
    bool silent = false,
  }) async {
    final stopwatch = PerfDebug.start('fleet.load');
    if (!silent) {
      emit(const FleetLoading());
    }
    try {
      if (DevModeManager.isDevMode) {
        _devLoadMockData();
        return;
      }

      // 1. Fetch available aircraft catalog models
      final List<dynamic> catalogResponse = await SupabaseManager.client
          .from('aircraft_models')
          .select()
          .order('purchase_price', ascending: true);

      final catalog = catalogResponse
          .map((m) => AircraftModel.fromMap(m))
          .toList();

      // 2. Fetch user owned/leased fleet with nested aircraft model details
      final List<dynamic> fleetResponse = await SupabaseManager.client
          .from('user_fleet')
          .select('*, aircraft_models(*)')
          .eq('user_id', userId)
          .order('acquired_at', ascending: false);

      final fleet = fleetResponse
          .map((f) => UserFleetAircraft.fromMap(f))
          .toList();

      _cachedCatalog = catalog;
      _cachedFleet = fleet;
      PerfDebug.end(
        'fleet.load',
        stopwatch,
        fields: {
          'silent': silent,
          'catalog': catalog.length,
          'fleet': fleet.length,
        },
      );

      emit(
        FleetLoaded(
          fleet: fleet,
          catalog: catalog,
          selectedManufacturers: _selectedManufacturers,
          selectedCategories: _selectedCategories,
          selectedRangeBrackets: _selectedRangeBrackets,
          sortBy: _sortBy,
        ),
      );
    } catch (e, stack) {
      PerfDebug.end(
        'fleet.load',
        stopwatch,
        fields: {'silent': silent, 'error': true},
      );
      SupabaseManager.logError('loadFleetAndCatalog', e, stack);
      emit(
        FleetError(
          message: 'Failed to load fleet: ${e.toString()}',
          hasData: _cachedFleet.isNotEmpty || _cachedCatalog.isNotEmpty,
          fleet: List<UserFleetAircraft>.from(_cachedFleet),
          catalog: List<AircraftModel>.from(_cachedCatalog),
          selectedManufacturers: _selectedManufacturers,
          selectedCategories: _selectedCategories,
          selectedRangeBrackets: _selectedRangeBrackets,
          sortBy: _sortBy,
        ),
      );
    }
  }

  void _scheduleRealtimeRefresh(String userId) {
    PerfDebug.event('fleet.realtime_refresh_scheduled', fields: {'user': userId});
    _realtimeRefreshDebounce?.cancel();
    _realtimeRefreshDebounce = Timer(const Duration(milliseconds: 180), () {
      unawaited(loadFleetAndCatalog(userId, silent: true));
    });
  }

  // Atomically purchase a new aircraft via PostgreSQL transaction
  Future<bool> purchaseAircraft({
    required String userId,
    required String modelId,
    required String nickname,
    required int economy,
    required int business,
    required int firstClass,
    required FleetBalanceCallback onBalanceChanged,
  }) async {
    final snapshot = _snapshotState();
    emit(
      FleetActionLoading(
        fleet: snapshot.fleet,
        catalog: snapshot.catalog,
        selectedManufacturers: snapshot.selectedManufacturers,
        selectedCategories: snapshot.selectedCategories,
        selectedRangeBrackets: snapshot.selectedRangeBrackets,
        sortBy: snapshot.sortBy,
      ),
    );
    try {
      if (DevModeManager.isDevMode) {
        // Dev Fallback Buy Logic
        final model = _cachedCatalog.firstWhere((m) => m.id == modelId);
        final newAircraft = UserFleetAircraft(
          id: 'mock-aircraft-${DateTime.now().millisecondsSinceEpoch}',
          nickname: nickname,
          acquisitionType: 'purchase',
          condition: 100.00,
          status: 'active',
          acquiredAt: DateTime.now(),
          model: model,
          economySeats: economy,
          businessSeats: business,
          firstClassSeats: firstClass,
        );
        _cachedFleet.insert(0, newAircraft);

        emit(
          FleetActionSuccess(
            message: 'Successfully purchased aircraft!',
            fleet: List<UserFleetAircraft>.from(_cachedFleet),
            catalog: List<AircraftModel>.from(_cachedCatalog),
            selectedManufacturers: _selectedManufacturers,
            selectedCategories: _selectedCategories,
            selectedRangeBrackets: _selectedRangeBrackets,
            sortBy: _sortBy,
          ),
        );
        _emitLoaded();
        return true;
      }

      final List<dynamic> response = await SupabaseManager.client.rpc(
        'purchase_aircraft',
        params: {
          'p_model_id': modelId,
          'p_nickname': nickname,
          'p_economy_seats': economy,
          'p_business_seats': business,
          'p_first_class_seats': firstClass,
        },
      );

      if (response.isNotEmpty) {
        final result = response[0] as Map<String, dynamic>;
        final success = result['success'] as bool? ?? false;
        final message = result['message'] as String? ?? 'Purchase failed';
        final newCash = (result['new_cash'] as num?)?.toDouble();

        if (success) {
          if (newCash != null) {
            await onBalanceChanged(newCash);
          }

          _suppressNextFleetRealtimeReload = true;
          await _appendLatestAircraftToCache(userId: userId, modelId: modelId);

          emit(
            FleetActionSuccess(
              message: message,
              fleet: _cachedFleet,
              catalog: snapshot.catalog,
              selectedManufacturers: snapshot.selectedManufacturers,
              selectedCategories: snapshot.selectedCategories,
              selectedRangeBrackets: snapshot.selectedRangeBrackets,
              sortBy: snapshot.sortBy,
            ),
          );
          _emitLoaded();
          return true;
        } else {
          SupabaseManager.logRpcFailure('purchase_aircraft', {
            'p_user_id': userId,
            'p_model_id': modelId,
            'p_nickname': nickname,
          }, message);
          emit(
            FleetError(
              message: message,
              hasData: true,
              fleet: snapshot.fleet,
              catalog: snapshot.catalog,
              selectedManufacturers: snapshot.selectedManufacturers,
              selectedCategories: snapshot.selectedCategories,
              selectedRangeBrackets: snapshot.selectedRangeBrackets,
              sortBy: snapshot.sortBy,
            ),
          );
          _emitLoaded();
          return false;
        }
      } else {
        const errorMsg = 'Database transaction returned an empty response.';
        SupabaseManager.logRpcFailure('purchase_aircraft', {
          'p_user_id': userId,
          'p_model_id': modelId,
        }, errorMsg);
        emit(
          FleetError(
            message: errorMsg,
            hasData: true,
            fleet: snapshot.fleet,
            catalog: snapshot.catalog,
            selectedManufacturers: snapshot.selectedManufacturers,
            selectedCategories: snapshot.selectedCategories,
            selectedRangeBrackets: snapshot.selectedRangeBrackets,
            sortBy: snapshot.sortBy,
          ),
        );
        _emitLoaded();
        return false;
      }
    } catch (e, stack) {
      SupabaseManager.logError('purchase_aircraft', e, stack);
      emit(
        FleetError(
          message: 'Database connection failed: ${e.toString()}',
          hasData: true,
          fleet: snapshot.fleet,
          catalog: snapshot.catalog,
          selectedManufacturers: snapshot.selectedManufacturers,
          selectedCategories: snapshot.selectedCategories,
          selectedRangeBrackets: snapshot.selectedRangeBrackets,
          sortBy: snapshot.sortBy,
        ),
      );
      _emitLoaded();
      return false;
    }
  }

  // Atomically lease a new aircraft
  Future<bool> leaseAircraft({
    required String userId,
    required String modelId,
    required String nickname,
    required int economy,
    required int business,
    required int firstClass,
    required FleetBalanceCallback onBalanceChanged,
  }) async {
    final snapshot = _snapshotState();
    emit(
      FleetActionLoading(
        fleet: snapshot.fleet,
        catalog: snapshot.catalog,
        selectedManufacturers: snapshot.selectedManufacturers,
        selectedCategories: snapshot.selectedCategories,
        selectedRangeBrackets: snapshot.selectedRangeBrackets,
        sortBy: snapshot.sortBy,
      ),
    );
    try {
      if (DevModeManager.isDevMode) {
        // Dev Fallback Lease Logic
        final model = _cachedCatalog.firstWhere((m) => m.id == modelId);
        final newAircraft = UserFleetAircraft(
          id: 'mock-aircraft-${DateTime.now().millisecondsSinceEpoch}',
          nickname: nickname,
          acquisitionType: 'lease',
          condition: 100.00,
          status: 'active',
          acquiredAt: DateTime.now(),
          model: model,
          economySeats: economy,
          businessSeats: business,
          firstClassSeats: firstClass,
        );
        _cachedFleet.insert(0, newAircraft);

        emit(
          FleetActionSuccess(
            message: 'Successfully leased aircraft!',
            fleet: List<UserFleetAircraft>.from(_cachedFleet),
            catalog: List<AircraftModel>.from(_cachedCatalog),
            selectedManufacturers: _selectedManufacturers,
            selectedCategories: _selectedCategories,
            selectedRangeBrackets: _selectedRangeBrackets,
            sortBy: _sortBy,
          ),
        );
        _emitLoaded();
        return true;
      }

      final List<dynamic> response = await SupabaseManager.client.rpc(
        'lease_aircraft',
        params: {
          'p_model_id': modelId,
          'p_nickname': nickname,
          'p_economy_seats': economy,
          'p_business_seats': business,
          'p_first_class_seats': firstClass,
        },
      );

      if (response.isNotEmpty) {
        final result = response[0] as Map<String, dynamic>;
        final success = result['success'] as bool? ?? false;
        final message = result['message'] as String? ?? 'Lease failed';
        final newCash = (result['new_cash'] as num?)?.toDouble();

        if (success) {
          if (newCash != null) {
            await onBalanceChanged(newCash);
          }

          _suppressNextFleetRealtimeReload = true;
          await _appendLatestAircraftToCache(userId: userId, modelId: modelId);

          emit(
            FleetActionSuccess(
              message: message,
              fleet: _cachedFleet,
              catalog: snapshot.catalog,
              selectedManufacturers: snapshot.selectedManufacturers,
              selectedCategories: snapshot.selectedCategories,
              selectedRangeBrackets: snapshot.selectedRangeBrackets,
              sortBy: snapshot.sortBy,
            ),
          );
          _emitLoaded();
          return true;
        } else {
          SupabaseManager.logRpcFailure('lease_aircraft', {
            'p_user_id': userId,
            'p_model_id': modelId,
            'p_nickname': nickname,
          }, message);
          emit(
            FleetError(
              message: message,
              hasData: true,
              fleet: snapshot.fleet,
              catalog: snapshot.catalog,
              selectedManufacturers: snapshot.selectedManufacturers,
              selectedCategories: snapshot.selectedCategories,
              selectedRangeBrackets: snapshot.selectedRangeBrackets,
              sortBy: snapshot.sortBy,
            ),
          );
          _emitLoaded();
          return false;
        }
      } else {
        const errorMsg = 'Database transaction returned an empty response.';
        SupabaseManager.logRpcFailure('lease_aircraft', {
          'p_user_id': userId,
          'p_model_id': modelId,
        }, errorMsg);
        emit(
          FleetError(
            message: errorMsg,
            hasData: true,
            fleet: snapshot.fleet,
            catalog: snapshot.catalog,
            selectedManufacturers: snapshot.selectedManufacturers,
            selectedCategories: snapshot.selectedCategories,
            selectedRangeBrackets: snapshot.selectedRangeBrackets,
            sortBy: snapshot.sortBy,
          ),
        );
        _emitLoaded();
        return false;
      }
    } catch (e, stack) {
      SupabaseManager.logError('lease_aircraft', e, stack);
      emit(
        FleetError(
          message: 'Database connection failed: ${e.toString()}',
          hasData: true,
          fleet: snapshot.fleet,
          catalog: snapshot.catalog,
          selectedManufacturers: snapshot.selectedManufacturers,
          selectedCategories: snapshot.selectedCategories,
          selectedRangeBrackets: snapshot.selectedRangeBrackets,
          sortBy: snapshot.sortBy,
        ),
      );
      _emitLoaded();
      return false;
    }
  }

  // Perform aircraft maintenance/repair
  Future<bool> repairAircraft({
    required String userId,
    required String fleetId,
    required FleetBalanceCallback onBalanceChanged,
  }) async {
    final snapshot = _snapshotState();
    emit(
      FleetActionLoading(
        fleet: snapshot.fleet,
        catalog: snapshot.catalog,
        selectedManufacturers: snapshot.selectedManufacturers,
        selectedCategories: snapshot.selectedCategories,
        selectedRangeBrackets: snapshot.selectedRangeBrackets,
        sortBy: snapshot.sortBy,
      ),
    );
    try {
      if (DevModeManager.isDevMode) {
        // Dev Fallback Repair Logic
        final idx = _cachedFleet.indexWhere((f) => f.id == fleetId);
        if (idx != -1) {
          final target = _cachedFleet[idx];
          _cachedFleet[idx] = UserFleetAircraft(
            id: target.id,
            nickname: target.nickname,
            acquisitionType: target.acquisitionType,
            condition: 100.00,
            status: 'active',
            acquiredAt: target.acquiredAt,
            model: target.model,
          );
        }
        emit(
          FleetActionSuccess(
            message: 'Aircraft repaired successfully!',
            fleet: List<UserFleetAircraft>.from(_cachedFleet),
            catalog: List<AircraftModel>.from(_cachedCatalog),
            selectedManufacturers: _selectedManufacturers,
            selectedCategories: _selectedCategories,
            selectedRangeBrackets: _selectedRangeBrackets,
            sortBy: _sortBy,
          ),
        );
        _emitLoaded();
        return true;
      }

      final List<dynamic> response = await SupabaseManager.client.rpc(
        'repair_aircraft',
        params: {'p_fleet_id': fleetId},
      );

      if (response.isNotEmpty) {
        final result = response[0] as Map<String, dynamic>;
        final success = result['success'] as bool? ?? false;
        final message = result['message'] as String? ?? 'Repair failed';
        final newCash = (result['new_cash'] as num?)?.toDouble();

        if (success) {
          if (newCash != null) {
            await onBalanceChanged(newCash);
          }

          emit(
            FleetActionSuccess(
              message: message,
              fleet: snapshot.fleet,
              catalog: snapshot.catalog,
              selectedManufacturers: snapshot.selectedManufacturers,
              selectedCategories: snapshot.selectedCategories,
              selectedRangeBrackets: snapshot.selectedRangeBrackets,
              sortBy: snapshot.sortBy,
            ),
          );
          _suppressNextFleetRealtimeReload = true;
          await _reloadSingleAircraftIntoCache(fleetId);
          _emitLoaded();
          return true;
        } else {
          SupabaseManager.logRpcFailure('repair_aircraft', {
            'p_user_id': userId,
            'p_fleet_id': fleetId,
          }, message);
          emit(
            FleetError(
              message: message,
              hasData: true,
              fleet: snapshot.fleet,
              catalog: snapshot.catalog,
              selectedManufacturers: snapshot.selectedManufacturers,
              selectedCategories: snapshot.selectedCategories,
              selectedRangeBrackets: snapshot.selectedRangeBrackets,
              sortBy: snapshot.sortBy,
            ),
          );
          _emitLoaded();
          return false;
        }
      } else {
        const errorMsg = 'Database transaction returned an empty response.';
        SupabaseManager.logRpcFailure('repair_aircraft', {
          'p_user_id': userId,
          'p_fleet_id': fleetId,
        }, errorMsg);
        emit(
          FleetError(
            message: errorMsg,
            hasData: true,
            fleet: snapshot.fleet,
            catalog: snapshot.catalog,
            selectedManufacturers: snapshot.selectedManufacturers,
            selectedCategories: snapshot.selectedCategories,
            selectedRangeBrackets: snapshot.selectedRangeBrackets,
            sortBy: snapshot.sortBy,
          ),
        );
        _emitLoaded();
        return false;
      }
    } catch (e, stack) {
      SupabaseManager.logError('repair_aircraft', e, stack);
      emit(
        FleetError(
          message: 'Database connection failed: ${e.toString()}',
          hasData: true,
          fleet: snapshot.fleet,
          catalog: snapshot.catalog,
          selectedManufacturers: snapshot.selectedManufacturers,
          selectedCategories: snapshot.selectedCategories,
          selectedRangeBrackets: snapshot.selectedRangeBrackets,
          sortBy: snapshot.sortBy,
        ),
      );
      _emitLoaded();
      return false;
    }
  }

  Future<bool> sellAircraft({
    required String userId,
    required String fleetId,
    required FleetBalanceCallback onBalanceChanged,
  }) async {
    final snapshot = _snapshotState();
    emit(
      FleetActionLoading(
        fleet: snapshot.fleet,
        catalog: snapshot.catalog,
        selectedManufacturers: snapshot.selectedManufacturers,
        selectedCategories: snapshot.selectedCategories,
        selectedRangeBrackets: snapshot.selectedRangeBrackets,
        sortBy: snapshot.sortBy,
      ),
    );
    try {
      if (DevModeManager.isDevMode) {
        final index = _cachedFleet.indexWhere(
          (aircraft) => aircraft.id == fleetId,
        );
        if (index == -1) {
          emit(
            FleetError(
              message: 'Aircraft not found.',
              hasData: true,
              fleet: snapshot.fleet,
              catalog: snapshot.catalog,
              selectedManufacturers: snapshot.selectedManufacturers,
              selectedCategories: snapshot.selectedCategories,
              selectedRangeBrackets: snapshot.selectedRangeBrackets,
              sortBy: snapshot.sortBy,
            ),
          );
          _emitLoaded();
          return false;
        }

        _cachedFleet.removeAt(index);
        emit(
          FleetActionSuccess(
            message: 'Aircraft sold successfully!',
            fleet: List<UserFleetAircraft>.from(_cachedFleet),
            catalog: snapshot.catalog,
            selectedManufacturers: snapshot.selectedManufacturers,
            selectedCategories: snapshot.selectedCategories,
            selectedRangeBrackets: snapshot.selectedRangeBrackets,
            sortBy: snapshot.sortBy,
          ),
        );
        _emitLoaded();
        return true;
      }

      final List<dynamic> response = await SupabaseManager.client.rpc(
        'sell_aircraft',
        params: {'p_fleet_id': fleetId},
      );

      final result = response.isNotEmpty
          ? response[0] as Map<String, dynamic>
          : <String, dynamic>{};
      final success = result['success'] as bool? ?? false;
      final message = result['message'] as String? ?? 'Aircraft sale failed.';
      final newCash = (result['new_cash'] as num?)?.toDouble();

      if (!success) {
        SupabaseManager.logRpcFailure('sell_aircraft', {
          'p_user_id': userId,
          'p_fleet_id': fleetId,
        }, message);
        emit(
          FleetError(
            message: message,
            hasData: true,
            fleet: snapshot.fleet,
            catalog: snapshot.catalog,
            selectedManufacturers: snapshot.selectedManufacturers,
            selectedCategories: snapshot.selectedCategories,
            selectedRangeBrackets: snapshot.selectedRangeBrackets,
            sortBy: snapshot.sortBy,
          ),
        );
        _emitLoaded();
        return false;
      }

      if (newCash != null) {
        await onBalanceChanged(newCash);
      }

      _suppressNextFleetRealtimeReload = true;
      _cachedFleet.removeWhere((aircraft) => aircraft.id == fleetId);
      emit(
        FleetActionSuccess(
          message: message,
          fleet: List<UserFleetAircraft>.from(_cachedFleet),
          catalog: snapshot.catalog,
          selectedManufacturers: snapshot.selectedManufacturers,
          selectedCategories: snapshot.selectedCategories,
          selectedRangeBrackets: snapshot.selectedRangeBrackets,
          sortBy: snapshot.sortBy,
        ),
      );
      _emitLoaded();
      return true;
    } catch (e, stack) {
      SupabaseManager.logError('sell_aircraft', e, stack);
      emit(
        FleetError(
          message: 'Failed to sell aircraft: ${e.toString()}',
          hasData: true,
          fleet: snapshot.fleet,
          catalog: snapshot.catalog,
          selectedManufacturers: snapshot.selectedManufacturers,
          selectedCategories: snapshot.selectedCategories,
          selectedRangeBrackets: snapshot.selectedRangeBrackets,
          sortBy: snapshot.sortBy,
        ),
      );
      _emitLoaded();
      return false;
    }
  }

  Future<bool> terminateLease({
    required String userId,
    required String fleetId,
    required FleetBalanceCallback onBalanceChanged,
  }) async {
    final snapshot = _snapshotState();
    emit(
      FleetActionLoading(
        fleet: snapshot.fleet,
        catalog: snapshot.catalog,
        selectedManufacturers: snapshot.selectedManufacturers,
        selectedCategories: snapshot.selectedCategories,
        selectedRangeBrackets: snapshot.selectedRangeBrackets,
        sortBy: snapshot.sortBy,
      ),
    );
    try {
      if (DevModeManager.isDevMode) {
        final index = _cachedFleet.indexWhere(
          (aircraft) => aircraft.id == fleetId,
        );
        if (index == -1) {
          emit(
            FleetError(
              message: 'Aircraft not found.',
              hasData: true,
              fleet: snapshot.fleet,
              catalog: snapshot.catalog,
              selectedManufacturers: snapshot.selectedManufacturers,
              selectedCategories: snapshot.selectedCategories,
              selectedRangeBrackets: snapshot.selectedRangeBrackets,
              sortBy: snapshot.sortBy,
            ),
          );
          _emitLoaded();
          return false;
        }

        _cachedFleet.removeAt(index);
        emit(
          FleetActionSuccess(
            message: 'Lease terminated successfully!',
            fleet: List<UserFleetAircraft>.from(_cachedFleet),
            catalog: snapshot.catalog,
            selectedManufacturers: snapshot.selectedManufacturers,
            selectedCategories: snapshot.selectedCategories,
            selectedRangeBrackets: snapshot.selectedRangeBrackets,
            sortBy: snapshot.sortBy,
          ),
        );
        _emitLoaded();
        return true;
      }

      final List<dynamic> response = await SupabaseManager.client.rpc(
        'terminate_aircraft_lease',
        params: {'p_fleet_id': fleetId},
      );

      final result = response.isNotEmpty
          ? response[0] as Map<String, dynamic>
          : <String, dynamic>{};
      final success = result['success'] as bool? ?? false;
      final message =
          result['message'] as String? ?? 'Lease termination failed.';
      final newCash = (result['new_cash'] as num?)?.toDouble();

      if (!success) {
        SupabaseManager.logRpcFailure('terminate_aircraft_lease', {
          'p_user_id': userId,
          'p_fleet_id': fleetId,
        }, message);
        emit(
          FleetError(
            message: message,
            hasData: true,
            fleet: snapshot.fleet,
            catalog: snapshot.catalog,
            selectedManufacturers: snapshot.selectedManufacturers,
            selectedCategories: snapshot.selectedCategories,
            selectedRangeBrackets: snapshot.selectedRangeBrackets,
            sortBy: snapshot.sortBy,
          ),
        );
        _emitLoaded();
        return false;
      }

      if (newCash != null) {
        await onBalanceChanged(newCash);
      }

      _suppressNextFleetRealtimeReload = true;
      _cachedFleet.removeWhere((aircraft) => aircraft.id == fleetId);
      emit(
        FleetActionSuccess(
          message: message,
          fleet: List<UserFleetAircraft>.from(_cachedFleet),
          catalog: snapshot.catalog,
          selectedManufacturers: snapshot.selectedManufacturers,
          selectedCategories: snapshot.selectedCategories,
          selectedRangeBrackets: snapshot.selectedRangeBrackets,
          sortBy: snapshot.sortBy,
        ),
      );
      _emitLoaded();
      return true;
    } catch (e, stack) {
      SupabaseManager.logError('terminate_aircraft_lease', e, stack);
      emit(
        FleetError(
          message: 'Failed to terminate lease: ${e.toString()}',
          hasData: true,
          fleet: snapshot.fleet,
          catalog: snapshot.catalog,
          selectedManufacturers: snapshot.selectedManufacturers,
          selectedCategories: snapshot.selectedCategories,
          selectedRangeBrackets: snapshot.selectedRangeBrackets,
          sortBy: snapshot.sortBy,
        ),
      );
      _emitLoaded();
      return false;
    }
  }

  // Configure aircraft seat allocations
  Future<bool> configureSeats({
    required String userId,
    required String aircraftId,
    required int economy,
    required int business,
    required int firstClass,
  }) async {
    final snapshot = _snapshotState();
    emit(
      FleetActionLoading(
        fleet: snapshot.fleet,
        catalog: snapshot.catalog,
        selectedManufacturers: snapshot.selectedManufacturers,
        selectedCategories: snapshot.selectedCategories,
        selectedRangeBrackets: snapshot.selectedRangeBrackets,
        sortBy: snapshot.sortBy,
      ),
    );
    try {
      if (DevModeManager.isDevMode) {
        // Dev Fallback
        final index = _cachedFleet.indexWhere((a) => a.id == aircraftId);
        if (index != -1) {
          final old = _cachedFleet[index];
          _cachedFleet[index] = UserFleetAircraft(
            id: old.id,
            nickname: old.nickname,
            acquisitionType: old.acquisitionType,
            condition: old.condition,
            status: old.status,
            acquiredAt: old.acquiredAt,
            model: old.model,
            economySeats: economy,
            businessSeats: business,
            firstClassSeats: firstClass,
            tailNumber: old.tailNumber,
          );
        }
        emit(
          FleetActionSuccess(
            message: 'Successfully updated seat configuration!',
            fleet: List<UserFleetAircraft>.from(_cachedFleet),
            catalog: List<AircraftModel>.from(_cachedCatalog),
            selectedManufacturers: _selectedManufacturers,
            selectedCategories: _selectedCategories,
            selectedRangeBrackets: _selectedRangeBrackets,
            sortBy: _sortBy,
          ),
        );
        _emitLoaded();
        return true;
      }

      final List<dynamic> response = await SupabaseManager.client.rpc(
        'configure_aircraft_seats',
        params: {
          'p_fleet_id': aircraftId,
          'p_economy_seats': economy,
          'p_business_seats': business,
          'p_first_class_seats': firstClass,
        },
      );

      final result = response.isNotEmpty
          ? response[0] as Map<String, dynamic>
          : <String, dynamic>{};
      final success = result['success'] as bool? ?? false;
      final message =
          result['message'] as String? ??
          'Failed to update seat configuration.';
      if (!success) {
        emit(
          FleetError(
            message: message,
            hasData: true,
            fleet: snapshot.fleet,
            catalog: snapshot.catalog,
            selectedManufacturers: snapshot.selectedManufacturers,
            selectedCategories: snapshot.selectedCategories,
            selectedRangeBrackets: snapshot.selectedRangeBrackets,
            sortBy: snapshot.sortBy,
          ),
        );
        _emitLoaded();
        return false;
      }

      emit(
        FleetActionSuccess(
          message: 'Successfully updated seat configuration!',
          fleet: snapshot.fleet,
          catalog: snapshot.catalog,
          selectedManufacturers: snapshot.selectedManufacturers,
          selectedCategories: snapshot.selectedCategories,
          selectedRangeBrackets: snapshot.selectedRangeBrackets,
          sortBy: snapshot.sortBy,
        ),
      );
      _suppressNextFleetRealtimeReload = true;
      await _reloadSingleAircraftIntoCache(aircraftId);
      _emitLoaded();
      return true;
    } catch (e) {
      emit(
        FleetError(
          message: 'Failed to configure seats: ${e.toString()}',
          hasData: true,
          fleet: snapshot.fleet,
          catalog: snapshot.catalog,
          selectedManufacturers: snapshot.selectedManufacturers,
          selectedCategories: snapshot.selectedCategories,
          selectedRangeBrackets: snapshot.selectedRangeBrackets,
          sortBy: snapshot.sortBy,
        ),
      );
      _emitLoaded();
      return false;
    }
  }

  void setManufacturerFilter(List<String> manufacturers) {
    _selectedManufacturers = manufacturers;
    _emitLoaded();
  }

  void setCategoryFilter(List<String> categories) {
    _selectedCategories = categories;
    _emitLoaded();
  }

  void setRangeBracketFilter(List<String> ranges) {
    _selectedRangeBrackets = ranges;
    _emitLoaded();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _emitLoaded();
  }

  Future<void> _appendLatestAircraftToCache({
    required String userId,
    required String modelId,
  }) async {
    final List<dynamic> fleetRecords = await SupabaseManager.client
        .from('user_fleet')
        .select('*, aircraft_models(*)')
        .eq('user_id', userId)
        .eq('aircraft_model_id', modelId)
        .order('acquired_at', ascending: false)
        .limit(1);

    if (fleetRecords.isEmpty) return;

    final aircraft = UserFleetAircraft.fromMap(fleetRecords.first);
    _cachedFleet.removeWhere((item) => item.id == aircraft.id);
    _cachedFleet.insert(0, aircraft);
  }

  Future<void> _reloadSingleAircraftIntoCache(String aircraftId) async {
    final Map<String, dynamic> fleetRecord = await SupabaseManager.client
        .from('user_fleet')
        .select('*, aircraft_models(*)')
        .eq('id', aircraftId)
        .single();

    final aircraft = UserFleetAircraft.fromMap(fleetRecord);
    final index = _cachedFleet.indexWhere((item) => item.id == aircraft.id);
    if (index == -1) {
      _cachedFleet.insert(0, aircraft);
    } else {
      _cachedFleet[index] = aircraft;
    }
  }

  // Seed Mock Data in Dev Mode
  void _devLoadMockData() {
    _cachedCatalog = [
      AircraftModel(
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
      AircraftModel(
        id: 'mock-a320neo',
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
      AircraftModel(
        id: 'mock-b787',
        manufacturer: 'Boeing',
        modelName: '787-9 Dreamliner',
        type: 'wide_body_jet',
        rangeKm: 14140,
        capacity: 290,
        speedKmh: 903,
        fuelBurnPerKm: 7.8,
        maintenanceCostPerHour: 1850.00,
        purchasePrice: 292000000.00,
        leasePricePerMonth: 1460000.00,
      ),
    ];

    _cachedFleet = [
      UserFleetAircraft(
        id: 'mock-owned-1',
        nickname: 'Primary Eagle',
        acquisitionType: 'purchase',
        condition: 82.50,
        status: 'active',
        acquiredAt: DateTime.now().subtract(const Duration(days: 10)),
        model: _cachedCatalog[1], // A320neo
      ),
      UserFleetAircraft(
        id: 'mock-owned-2',
        nickname: 'Short-Haul Hopper',
        acquisitionType: 'lease',
        condition: 45.00,
        status: 'active',
        acquiredAt: DateTime.now().subtract(const Duration(days: 3)),
        model: _cachedCatalog[0], // ATR 72
      ),
    ];

    _emitLoaded();
  }

  void _setupRealtime(String userId) {
    if (DevModeManager.isDevMode || SupabaseManager.hasMockClient) return;
    unawaited(_realtimeSubscriptions.clear());

    final fleetChannel = SupabaseManager.client
        .channel('public:user_fleet:user_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_fleet',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (_) {
            if (_suppressNextFleetRealtimeReload) {
              _suppressNextFleetRealtimeReload = false;
              return;
            }
            _scheduleRealtimeRefresh(userId);
          },
        )
        .subscribe();

    _realtimeSubscriptions.add(fleetChannel);
  }
}
