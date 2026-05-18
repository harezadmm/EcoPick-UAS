import '../../../core/config/supabase_config.dart';

class EcoPickService {
  /// Insert an EcoPick request for admin review. GreenCoin is credited only
  /// after an admin marks the request completed.
  Future<String?> submit({
    required String userId,
    required String categoryId,
    required double weightKg,
    required int estimatedGc,
    required String pickupAddress,
    String? notes,
  }) async {
    if (!SupabaseConfig.isConfigured) return null;

    final inserted = await SupabaseConfig.client
        .from('ecopick_requests')
        .insert({
          'user_id': userId,
          'category_id': categoryId,
          'estimated_weight_kg': weightKg,
          'estimated_green_coin': estimatedGc,
          'pickup_address': pickupAddress,
          'notes': notes,
          'status': 'pending',
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }
}
