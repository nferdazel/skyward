import '../../../core/database/supabase_client.dart';

abstract class SimulationGateway {
  Future<List<dynamic>> processSimulationDelta();
  Future<Map<String, dynamic>> loadUserProfile(String userId);
  Future<List<dynamic>> loadGameSettings();
}

class SupabaseSimulationGateway implements SimulationGateway {
  const SupabaseSimulationGateway();

  @override
  Future<List<dynamic>> processSimulationDelta() async {
    return SupabaseManager.client.rpc('process_simulation_delta');
  }

  @override
  Future<Map<String, dynamic>> loadUserProfile(String userId) async {
    return SupabaseManager.client
        .from('users')
        .select(
          'id, username, company_name, ceo_name, cash, game_current_time, '
          'hq_airport_iata, auto_grounding_threshold, operational_status, '
          'consecutive_negative_days, recovery_streak_days',
        )
        .eq('id', userId)
        .single();
  }

  @override
  Future<List<dynamic>> loadGameSettings() async {
    return SupabaseManager.client
        .from('global_game_settings')
        .select('fuel_price_per_liter, time_scale_multiplier')
        .limit(1);
  }
}
