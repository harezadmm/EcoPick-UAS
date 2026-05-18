import '../../../core/config/supabase_config.dart';
import '../models/greencoin_transaction.dart';

class GreenCoinService {
  Future<List<GreenCoinTransaction>> fetchTransactions(String userId) async {
    if (!SupabaseConfig.isConfigured) return const [];
    final rows = await SupabaseConfig.client
        .from('greencoin_transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    return [for (final r in rows) GreenCoinTransaction.fromMap(r)];
  }

  Future<int> fetchBalance(String userId) async {
    if (!SupabaseConfig.isConfigured) return 0;
    final row = await SupabaseConfig.client
        .from('profiles')
        .select('green_coin_balance')
        .eq('id', userId)
        .maybeSingle();
    return (row?['green_coin_balance'] as int?) ?? 0;
  }
}
