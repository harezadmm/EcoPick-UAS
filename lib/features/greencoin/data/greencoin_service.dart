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

  /// Melakukan penarikan secara atomik via RPC: validasi saldo, catat
  /// withdraw_request, catat transaksi, dan langsung potong saldo — semua
  /// dalam satu transaksi DB. Pakai RPC (SECURITY DEFINER) karena RLS
  /// melarang user menulis langsung ke greencoin_transactions (admin-only).
  /// Nilai rupiah dihitung server-side dari rate trusted, bukan dari client.
  Future<String> createWithdraw(String userId, WithdrawRequest request) async {
    if (!SupabaseConfig.isConfigured) throw Exception('Supabase not configured');

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
