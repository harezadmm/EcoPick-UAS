import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_config.dart';
import '../models/waste_category.dart';

final wasteCategoriesProvider = FutureProvider<List<WasteCategory>>((ref) async {
  if (!SupabaseConfig.isConfigured) {
    return WasteCategory.defaults;
  }
  final rows = await SupabaseConfig.client
      .from('waste_categories')
      .select()
      .eq('is_active', true)
      .order('name');
  return [for (final r in rows) WasteCategory.fromMap(r)];
});
