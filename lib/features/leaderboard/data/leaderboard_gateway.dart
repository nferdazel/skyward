import '../../../core/database/supabase_client.dart';

abstract class LeaderboardGateway {
  Future<List<dynamic>> getGlobalLeaderboard();
  Future<List<dynamic>> getCompetitorInsights(String id, bool isBot);
}

class SupabaseLeaderboardGateway implements LeaderboardGateway {
  const SupabaseLeaderboardGateway();

  @override
  Future<List<dynamic>> getGlobalLeaderboard() {
    return SupabaseManager.client.rpc('get_global_leaderboard');
  }

  @override
  Future<List<dynamic>> getCompetitorInsights(String id, bool isBot) {
    return SupabaseManager.client.rpc(
      'get_competitor_insights',
      params: {'p_id': id, 'p_is_bot': isBot},
    );
  }
}
