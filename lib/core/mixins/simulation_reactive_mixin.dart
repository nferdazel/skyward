import 'dart:async';

import 'package:flutter/material.dart';

/// Mixin for cubits that need to react to SimulationCubit sync completion events.
///
/// Provides subscription management to avoid code duplication.
///
/// Usage:
/// ```dart
/// void setupReactivity(dynamic simCubit, String userId) {
///   subscribeToSimulation(simCubit, () => loadData(userId, silent: true));
/// }
/// ```
mixin SimulationReactiveMixin {
  StreamSubscription? _simSubscription;
  bool _wasSyncing = false;

  /// Subscribes to simulation stream and calls [onSyncComplete] when sync
  /// transitions from true → false with no error.
  void subscribeToSimulation(dynamic simCubit, VoidCallback onSyncComplete) {
    _simSubscription?.cancel();
    _wasSyncing = false;
    _simSubscription = simCubit.stream.listen((dynamic simState) {
      final isSyncing = simState.isSyncing as bool;
      if (_wasSyncing && !isSyncing && simState.errorMessage == null) {
        onSyncComplete();
      }
      _wasSyncing = isSyncing;
    });
  }

  /// Subscribes to simulation stream and calls [onSyncComplete] with the simState
  /// when sync transitions from true → false with no error.
  void subscribeToSimulationWithState(
    dynamic simCubit,
    void Function(dynamic simState) onSyncComplete,
  ) {
    _simSubscription?.cancel();
    _wasSyncing = false;
    _simSubscription = simCubit.stream.listen((dynamic simState) {
      final isSyncing = simState.isSyncing as bool;
      if (_wasSyncing && !isSyncing && simState.errorMessage == null) {
        onSyncComplete(simState);
      }
      _wasSyncing = isSyncing;
    });
  }

  /// Cancel simulation subscription. Call from cubit's [close()].
  void disposeReactivity() {
    _simSubscription?.cancel();
    _simSubscription = null;
  }
}
