import '../../../core/config/supabase_config.dart';
import '../models/greencoin_transaction.dart';
import '../models/withdraw_request.dart';

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

  Future<String> createWithdraw(String userId, WithdrawRequest request) async {
    if (!SupabaseConfig.isConfigured) throw Exception('Supabase not configured');

    // Create transaction record
    final result = await SupabaseConfig.client
        .from('greencoin_transactions')
        .insert({
          'user_id': userId,
          'amount_gc': -request.amountGc,
          'amount_rupiah': -request.amountRupiah,
          'source_type': 'withdraw',
          'status': 'process',
          'description': 'Withdraw ke ${request.walletType} ${request.maskedAccount}',
        })
        .select('id')
        .single();

    // Update user balance
    await SupabaseConfig.client
        .from('profiles')
        .update({'green_coin_balance': request.remainingBalanceGc})
        .eq('id', userId);

    return result['id'] as String;
  }
}
