import '../../../core/database/supabase_client.dart';

/// Abstraction over the Supabase data source for route operations.
///
/// Keeps all direct Supabase I/O out of [RoutesCubit] so the cubit only
/// handles state management, caching, and dev-mode fallbacks.
abstract class RoutesGateway {
  Future<List<dynamic>> loadAirports();
  Future<List<dynamic>> loadRoutes(String userId);
  Future<Map<String, dynamic>> loadUserThreshold(String userId);
  Future<List<dynamic>> loadAvailableFleet(String userId);
  Future<List<dynamic>> createRoute({
    required String originIata,
    required String destinationIata,
    required double distanceKm,
    required double ticketPrice,
    required int flightsPerWeek,
  });
  Future<List<dynamic>> assignAircraft({
    required String routeId,
    required String? aircraftId,
  });
  Future<List<dynamic>> updateRouteFrequencyAndPrice({
    required String routeId,
    required double ticketPrice,
    required int flightsPerWeek,
  });
  Future<List<dynamic>> deleteRoute({required String routeId});
}

class SupabaseRoutesGateway implements RoutesGateway {
  const SupabaseRoutesGateway();

  @override
  Future<List<dynamic>> loadAirports() {
    return SupabaseManager.client
        .from('airports')
        .select()
        .order('iata', ascending: true);
  }

  @override
  Future<List<dynamic>> loadRoutes(String userId) {
    return SupabaseManager.client
        .from('user_routes')
        .select(
          '*, origin:airports!origin_iata(*), '
          'destination:airports!destination_iata(*), '
          'user_fleet(*, aircraft_models(*))',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  @override
  Future<Map<String, dynamic>> loadUserThreshold(String userId) async {
    return SupabaseManager.client
        .from('users')
        .select('auto_grounding_threshold')
        .eq('id', userId)
        .single();
  }

  @override
  Future<List<dynamic>> loadAvailableFleet(String userId) {
    return SupabaseManager.client
        .from('user_fleet')
        .select('*, aircraft_models(*)')
        .eq('user_id', userId);
  }

  @override
  Future<List<dynamic>> createRoute({
    required String originIata,
    required String destinationIata,
    required double distanceKm,
    required double ticketPrice,
    required int flightsPerWeek,
  }) {
    return SupabaseManager.client.rpc(
      'create_route',
      params: {
        'p_origin_iata': originIata,
        'p_destination_iata': destinationIata,
        'p_distance_km': distanceKm,
        'p_ticket_price': ticketPrice,
        'p_flights_per_week': flightsPerWeek,
      },
    );
  }

  @override
  Future<List<dynamic>> assignAircraft({
    required String routeId,
    required String? aircraftId,
  }) {
    return SupabaseManager.client.rpc(
      'assign_aircraft_to_route',
      params: {
        'p_route_id': routeId,
        'p_aircraft_id': aircraftId,
      },
    );
  }

  @override
  Future<List<dynamic>> updateRouteFrequencyAndPrice({
    required String routeId,
    required double ticketPrice,
    required int flightsPerWeek,
  }) {
    return SupabaseManager.client.rpc(
      'update_route_frequency_and_price',
      params: {
        'p_route_id': routeId,
        'p_ticket_price': ticketPrice,
        'p_flights_per_week': flightsPerWeek,
      },
    );
  }

  @override
  Future<List<dynamic>> deleteRoute({required String routeId}) {
    return SupabaseManager.client.rpc(
      'delete_route',
      params: {'p_route_id': routeId},
    );
  }
}
