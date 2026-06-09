import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/errors/app_exception.dart';
import '../models/marketplace_product.dart';

class MarketplaceService {
  Future<List<MarketplaceProduct>> fetchProducts() async {
    if (!SupabaseConfig.isConfigured) {
      return MarketplaceProduct.demoList;
    }
    final rows = await SupabaseConfig.client
        .from('marketplace_products')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false);
    return [for (final r in rows) MarketplaceProduct.fromMap(r)];
  }

  Future<void> exchange({
    required String userId,
    required MarketplaceProduct product,
    int quantity = 1,
  }) async {
    if (!SupabaseConfig.isConfigured) return;
    final client = SupabaseConfig.client;

    // Atomic purchase via RPC (SECURITY DEFINER): validates stock + balance,
    // creates the order, deducts balance, AND decrements stock in one
    // transaction. Needed because RLS makes marketplace_products admin-only
    // for writes, so a client-side stock UPDATE silently fails.
    try {
      await client.rpc('purchase_product', params: {
        'p_product_id': product.id,
        'p_quantity': quantity,
      });
    } on PostgrestException catch (e) {
      final msg = e.message;
      if (msg.contains('Saldo')) {
        throw const InsufficientBalanceException();
      }
      throw AppException(msg);
    }
  }
}
