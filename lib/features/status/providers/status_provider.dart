import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/waste_request.dart';

export '../models/waste_request.dart';

/// Mengambil seluruh request EcoPick dan EcoDrop milik user yang sedang login,
/// diurutkan dari yang terbaru. Join ke `waste_categories` untuk nama kategori.
final userWasteRequestsProvider =
    FutureProvider<List<WasteRequest>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  if (!SupabaseConfig.isConfigured) return const [];

  final client = SupabaseConfig.client;

  // Fetch EcoPick requests
  final ecopickRows = await client
      .from('ecopick_requests')
      .select('id, status, created_at, estimated_weight_kg, estimated_green_coin, waste_categories:category_id(name)')
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  // Fetch EcoDrop requests
  final ecodropRows = await client
      .from('ecodrop_requests')
      .select('id, status, created_at, estimated_weight_kg, estimated_green_coin, waste_categories:category_id(name)')
      .eq('user_id', user.id)
      .order('created_at', ascending: false);

  final ecopickRequests = [
    for (final r in ecopickRows)
      WasteRequest.fromMap(r as Map<String, dynamic>, type: 'EcoPick'),
  ];

  final ecodropRequests = [
    for (final r in ecodropRows)
      WasteRequest.fromMap(r as Map<String, dynamic>, type: 'EcoDrop'),
  ];

  // Gabung dan urutkan berdasarkan tanggal terbaru
  final all = [...ecopickRequests, ...ecodropRequests]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return all;
});
