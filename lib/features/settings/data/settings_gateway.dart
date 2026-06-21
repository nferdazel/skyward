import '../../../core/database/supabase_client.dart';

abstract class SettingsGateway {
  Future<List<dynamic>> loadAirports();
  Future<List<dynamic>> saveAirlineSettings(Map<String, dynamic> params);
  Future<List<dynamic>> resetUserAirline();
}

class SupabaseSettingsGateway implements SettingsGateway {
  const SupabaseSettingsGateway();

  @override
  Future<List<dynamic>> loadAirports() async {
    return SupabaseManager.client
        .from('airports')
        .select('iata, name, city, country')
        .order('country', ascending: true);
  }

  @override
  Future<List<dynamic>> saveAirlineSettings(Map<String, dynamic> params) async {
    return SupabaseManager.client.rpc(
      'save_airline_settings',
      params: params,
    );
  }

  @override
  Future<List<dynamic>> resetUserAirline() async {
    return SupabaseManager.client.rpc('reset_user_airline');
  }
}
