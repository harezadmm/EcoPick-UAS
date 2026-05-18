import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_strings.dart';

class EcoDropService {
  Future<String?> submit({
    required String userId,
    required String categoryId,
    required double weightKg,
    required int estimatedGc,
    String? notes,
  }) async {
    if (!SupabaseConfig.isConfigured) return null;

    final inserted = await SupabaseConfig.client
        .from('ecodrop_requests')
        .insert({
          'user_id': userId,
          'category_id': categoryId,
          'estimated_weight_kg': weightKg,
          'estimated_green_coin': estimatedGc,
          'bank_sampah_location': AppStrings.defaultBankSampah,
          'notes': notes,
          'status': 'pending',
        })
        .select('id')
        .single();

    return inserted['id'] as String;
  }
}
