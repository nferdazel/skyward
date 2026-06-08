import '../../../fleet/domain/fleet_models.dart';
import '../../domain/route_models.dart';

abstract class RoutesState {
  const RoutesState();
}

abstract class RoutesDataState extends RoutesState {
  final List<UserRoute> routes;
  final List<Airport> airports;
  final List<UserFleetAircraft> availableAircraft;
  final RouteMaintenancePreview? plannerMaintenancePreview;
  final RouteMaintenancePreview? adjustmentMaintenancePreview;

  const RoutesDataState({
    required this.routes,
    required this.airports,
    required this.availableAircraft,
    this.plannerMaintenancePreview,
    this.adjustmentMaintenancePreview,
  });
}

class RoutesInitial extends RoutesState {
  const RoutesInitial();
}

class RoutesLoading extends RoutesState {
  const RoutesLoading();
}

class RoutesLoaded extends RoutesDataState {
  const RoutesLoaded({
    required super.routes,
    required super.airports,
    required super.availableAircraft,
    super.plannerMaintenancePreview,
    super.adjustmentMaintenancePreview,
  }) : super();
}

class RoutesActionLoading extends RoutesDataState {
  const RoutesActionLoading({
    required super.routes,
    required super.airports,
    required super.availableAircraft,
    super.plannerMaintenancePreview,
    super.adjustmentMaintenancePreview,
  });
}

class RoutesActionSuccess extends RoutesDataState {
  final String message;

  const RoutesActionSuccess({
    required this.message,
    required super.routes,
    required super.airports,
    required super.availableAircraft,
    super.plannerMaintenancePreview,
    super.adjustmentMaintenancePreview,
  });
}

class RoutesError extends RoutesDataState {
  final String message;

  final bool hasData;

  const RoutesError({
    required this.message,
    this.hasData = false,
    super.routes = const [],
    super.airports = const [],
    super.availableAircraft = const [],
    super.plannerMaintenancePreview,
    super.adjustmentMaintenancePreview,
  });
}
