import '../../../core/database/supabase_client.dart';

abstract class FleetGateway {
  Future<List<dynamic>> loadFleet(String userId);
  Future<List<dynamic>> loadCatalog();
  Future<List<dynamic>> purchaseAircraft(Map<String, dynamic> params);
  Future<List<dynamic>> leaseAircraft(Map<String, dynamic> params);
  Future<List<dynamic>> repairAircraft(Map<String, dynamic> params);
  Future<List<dynamic>> sellAircraft(Map<String, dynamic> params);
  Future<List<dynamic>> terminateLease(Map<String, dynamic> params);
  Future<List<dynamic>> configureSeats(Map<String, dynamic> params);
  Future<List<dynamic>> fetchLatestAircraftForModel(
    String userId,
    String modelId,
  );
  Future<Map<String, dynamic>> fetchSingleAircraft(String aircraftId);
}

class SupabaseFleetGateway implements FleetGateway {
  @override
  Future<List<dynamic>> loadFleet(String userId) {
    return SupabaseManager.client
        .from('user_fleet')
        .select('*, aircraft_models(*)')
        .eq('user_id', userId)
        .order('acquired_at', ascending: false);
  }

  @override
  Future<List<dynamic>> loadCatalog() {
    return SupabaseManager.client
        .from('aircraft_models')
        .select()
        .order('purchase_price', ascending: true);
  }

  @override
  Future<List<dynamic>> purchaseAircraft(Map<String, dynamic> params) {
    return SupabaseManager.client.rpc('purchase_aircraft', params: params);
  }

  @override
  Future<List<dynamic>> leaseAircraft(Map<String, dynamic> params) {
    return SupabaseManager.client.rpc('lease_aircraft', params: params);
  }

  @override
  Future<List<dynamic>> repairAircraft(Map<String, dynamic> params) {
    return SupabaseManager.client.rpc('repair_aircraft', params: params);
  }

  @override
  Future<List<dynamic>> sellAircraft(Map<String, dynamic> params) {
    return SupabaseManager.client.rpc('sell_aircraft', params: params);
  }

  @override
  Future<List<dynamic>> terminateLease(Map<String, dynamic> params) {
    return SupabaseManager.client
        .rpc('terminate_aircraft_lease', params: params);
  }

  @override
  Future<List<dynamic>> configureSeats(Map<String, dynamic> params) {
    return SupabaseManager.client
        .rpc('configure_aircraft_seats', params: params);
  }

  @override
  Future<List<dynamic>> fetchLatestAircraftForModel(
    String userId,
    String modelId,
  ) {
    return SupabaseManager.client
        .from('user_fleet')
        .select('*, aircraft_models(*)')
        .eq('user_id', userId)
        .eq('aircraft_model_id', modelId)
        .order('acquired_at', ascending: false)
        .limit(1);
  }

  @override
  Future<Map<String, dynamic>> fetchSingleAircraft(String aircraftId) {
    return SupabaseManager.client
        .from('user_fleet')
        .select('*, aircraft_models(*)')
        .eq('id', aircraftId)
        .single();
  }
}
