import '../../../core/config/supabase_config.dart';
import '../models/dashboard_summary.dart';

class DashboardService {
  Future<DashboardSummary> fetch(String userId) async {
    if (!SupabaseConfig.isConfigured) {
      return DashboardSummary.empty;
    }
    final client = SupabaseConfig.client;

    final profile = await client
        .from('profiles')
        .select('green_coin_balance')
        .eq('id', userId)
        .maybeSingle();

    final balance = (profile?['green_coin_balance'] as int?) ?? 0;

    final ecopicks = await client
        .from('ecopick_requests')
        .select('estimated_weight_kg, status, created_at, category_id')
        .eq('user_id', userId)
        .eq('status', 'completed');

    final ecodrops = await client
        .from('ecodrop_requests')
        .select('estimated_weight_kg, status, created_at, category_id')
        .eq('user_id', userId)
        .eq('status', 'completed');

    final all = [...ecopicks, ...ecodrops];

    double totalKg = 0;
    for (final row in all) {
      totalKg += ((row['estimated_weight_kg'] as num?) ?? 0).toDouble();
    }

    // Weekly chart: Sun..Sat keyed 0..6 — count weight per day for last 7 days
    final now = DateTime.now();
    final weights = List<double>.filled(7, 0);
    for (final row in all) {
      final dt = DateTime.tryParse(row['created_at'] as String? ?? '');
      if (dt == null) continue;
      final diff = now.difference(dt).inDays;
      if (diff < 0 || diff > 6) continue;
      final idx = 6 - diff; // 0 = oldest day, 6 = today
      weights[idx] += ((row['estimated_weight_kg'] as num?) ?? 0).toDouble();
    }

    // Category breakdown
    final cats = await client
        .from('waste_categories')
        .select('id, name')
        .eq('is_active', true);
    final catNameById = <String, String>{
      for (final c in cats) c['id'] as String: c['name'] as String,
    };
    final weightByCat = <String, double>{};
    for (final row in all) {
      final id = row['category_id'] as String?;
      if (id == null) continue;
      weightByCat[id] = (weightByCat[id] ?? 0) +
          ((row['estimated_weight_kg'] as num?) ?? 0).toDouble();
    }

    const palette = [
      0xFF22C55E,
      0xFF3B82F6,
      0xFFF59E0B,
      0xFF8B5CF6,
      0xFFEC4899,
      0xFF14B8A6,
      0xFF9CA3AF,
    ];

    final shares = <CategoryShare>[];
    if (totalKg > 0) {
      var i = 0;
      final entries = weightByCat.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in entries) {
        shares.add(CategoryShare(
          name: catNameById[e.key] ?? 'Lainnya',
          percent: e.value / totalKg,
          color: palette[i % palette.length],
        ));
        i++;
      }
    }

    return DashboardSummary(
      greenCoinBalance: balance,
      totalWasteKg: totalKg,
      totalTransactions: all.length,
      co2SavedKg: totalKg * 0.34,
      weeklyWeights: weights,
      categoryShares: shares,
    );
  }
}
