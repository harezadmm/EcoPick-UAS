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
    return (row?['green_coin_balance'] as num?)?.toInt() ?? 0;
  }

  /// Menyimpan permintaan penarikan dengan status [pending].
  /// Saldo belum dipotong — admin harus menyetujui terlebih dahulu.
  /// Setelah admin approve, saldo dikurangi dan status menjadi [completed].
  /// Jika admin reject, status menjadi [rejected] dan saldo tetap utuh.
  Future<String> createWithdraw(String userId, WithdrawRequest request) async {
    if (!SupabaseConfig.isConfigured) throw Exception('Supabase not configured');

    // Encode wallet & account info into description so admin can see it
    final description =
        '${request.walletType} • ${request.maskedAccount} • ${request.accountName}';

    final row = await SupabaseConfig.client
        .from('greencoin_transactions')
        .insert({
          'user_id': userId,
          'source_type': 'withdraw',
          'transaction_type': 'spend',
          // Negative amount indicates outflow; balance NOT deducted until admin approves
          'amount_gc': -(request.amountGc.abs()),
          'status': 'pending',
          'description': description,
        })
        .select('id')
        .single();

    return row['id'] as String;
  }
}
