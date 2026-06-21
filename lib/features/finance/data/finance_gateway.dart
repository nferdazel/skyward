import '../../../core/database/supabase_client.dart';

abstract class FinanceGateway {
  Future<List<dynamic>> loadLedger(String userId);
  Future<Map<String, dynamic>> getFinanceSnapshot();
}

class SupabaseFinanceGateway implements FinanceGateway {
  const SupabaseFinanceGateway();

  @override
  Future<List<dynamic>> loadLedger(String userId) async {
    return SupabaseManager.client
        .from('financial_ledger')
        .select(
          'id, transaction_type, category, amount, description, game_date, created_at',
        )
        .eq('user_id', userId)
        .order('game_date', ascending: false);
  }

  @override
  Future<Map<String, dynamic>> getFinanceSnapshot() async {
    final snapshotResponse = await SupabaseManager.client.rpc(
      'get_finance_snapshot',
    );
    if (snapshotResponse is List<dynamic> && snapshotResponse.isNotEmpty) {
      return snapshotResponse.first as Map<String, dynamic>;
    }
    return <String, dynamic>{};
  }
}
