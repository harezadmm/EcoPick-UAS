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

    final productRow = await client
        .from('marketplace_products')
        .select('stock, is_active')
        .eq('id', product.id)
        .maybeSingle();
    final latestStock = productRow?['stock'] as int? ?? product.stock;
    final isActive = productRow?['is_active'] as bool? ?? product.isActive;

    if (!isActive) {
      throw const AppException('Produk ini sudah tidak aktif');
    }
    if (latestStock < quantity) {
      throw const AppException('Stok produk tidak mencukupi');
    }

    final totalGc = product.priceGc * quantity;
    final profile = await client
        .from('profiles')
        .select('green_coin_balance')
        .eq('id', userId)
        .maybeSingle();
    final balance = profile?['green_coin_balance'] as int? ?? 0;
    if (balance < totalGc) {
      throw const InsufficientBalanceException();
    }

    final inserted = await client
        .from('marketplace_orders')
        .insert({
          'user_id': userId,
          'product_id': product.id,
          'quantity': quantity,
          'total_price_gc': totalGc,
          'status': 'completed',
        })
        .select('id')
        .single();
    final orderId = inserted['id'] as String;

    await client.rpc('adjust_balance', params: {
      'p_user_id': userId,
      'p_amount': -totalGc,
      'p_source_type': 'marketplace',
      'p_source_id': orderId,
      'p_transaction_type': 'exchange',
      'p_description': 'Tukar ${product.name} × $quantity',
    });

    await client
        .from('marketplace_products')
        .update({'stock': latestStock - quantity}).eq('id', product.id);
  }
}
