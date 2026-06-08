import '../../domain/fleet_models.dart';

abstract class FleetState {
  const FleetState();
}

abstract class FleetDataState extends FleetState {
  final List<UserFleetAircraft> fleet;
  final List<AircraftModel> catalog;
  final List<String> selectedManufacturers;
  final List<String> selectedCategories;
  final List<String> selectedRangeBrackets;
  final String sortBy;

  const FleetDataState({
    required this.fleet,
    required this.catalog,
    this.selectedManufacturers = const [],
    this.selectedCategories = const [],
    this.selectedRangeBrackets = const [],
    this.sortBy = 'price_asc',
  });
}

class FleetInitial extends FleetState {
  const FleetInitial();
}

class FleetLoading extends FleetState {
  const FleetLoading();
}

class FleetLoaded extends FleetDataState {
  const FleetLoaded({
    required super.fleet,
    required super.catalog,
    super.selectedManufacturers = const [],
    super.selectedCategories = const [],
    super.selectedRangeBrackets = const [],
    super.sortBy = 'price_asc',
  }) : super();

  FleetLoaded copyWith({
    List<UserFleetAircraft>? fleet,
    List<AircraftModel>? catalog,
    List<String>? selectedManufacturers,
    List<String>? selectedCategories,
    List<String>? selectedRangeBrackets,
    String? sortBy,
  }) {
    return FleetLoaded(
      fleet: fleet ?? this.fleet,
      catalog: catalog ?? this.catalog,
      selectedManufacturers:
          selectedManufacturers ?? this.selectedManufacturers,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedRangeBrackets:
          selectedRangeBrackets ?? this.selectedRangeBrackets,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class FleetActionLoading extends FleetDataState {
  const FleetActionLoading({
    required super.fleet,
    required super.catalog,
    super.selectedManufacturers,
    super.selectedCategories,
    super.selectedRangeBrackets,
    super.sortBy,
  });
}

class FleetActionSuccess extends FleetDataState {
  final String message;

  const FleetActionSuccess({
    required this.message,
    required super.fleet,
    required super.catalog,
    super.selectedManufacturers,
    super.selectedCategories,
    super.selectedRangeBrackets,
    super.sortBy,
  });
}

class FleetError extends FleetDataState {
  final String message;

  const FleetError({
    required this.message,
    this.hasData = false,
    super.fleet = const [],
    super.catalog = const [],
    super.selectedManufacturers = const [],
    super.selectedCategories = const [],
    super.selectedRangeBrackets = const [],
    super.sortBy = 'price_asc',
  });

  final bool hasData;
}
