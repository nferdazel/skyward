import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/supabase_client.dart';

class RealtimeSubscriptionBag {
  final List<RealtimeChannel> _channels = [];

  void add(RealtimeChannel channel) {
    _channels.add(channel);
  }

  Future<void> clear() async {
    for (final channel in _channels) {
      await SupabaseManager.client.removeChannel(channel);
    }
    _channels.clear();
  }
}
