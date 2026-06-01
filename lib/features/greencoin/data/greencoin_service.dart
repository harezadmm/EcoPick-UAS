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

    // Atomic withdrawal via RPC: creates the request, records the transaction,
    // and deducts the balance in one transaction (bypasses admin-only RLS on
    // greencoin_transactions via SECURITY DEFINER while verifying ownership).
    // The rupiah payout is computed server-side from a trusted rate, never
    // sent by the client, so it can't be tampered with.
    final id = await SupabaseConfig.client.rpc(
      'withdraw_greencoin',
      params: {
        'p_wallet_provider': request.walletType,
        'p_account_number': request.accountNumber,
        'p_amount_gc': request.amountGc,
      },
    );

    return id as String;
  }
}
