import '../../../core/constants/app_strings.dart';

/// Model untuk menampilkan request EcoPick atau EcoDrop di halaman Status.
class WasteRequest {
  final String id;
  final String type; // 'EcoPick' atau 'EcoDrop'
  final TransactionStatus status;
  final DateTime createdAt;
  final String categoryName;
  final double weightKg;
  final int estimatedGc;

  const WasteRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.categoryName,
    required this.weightKg,
    required this.estimatedGc,
  });

  factory WasteRequest.fromMap(Map<String, dynamic> map, {required String type}) {
    final statusStr = map['status'] as String? ?? 'pending';
    final status = TransactionStatus.values.firstWhere(
      (s) => s.value == statusStr,
      orElse: () => TransactionStatus.pending,
    );
    return WasteRequest(
      id: map['id'] as String,
      type: type,
      status: status,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      categoryName: (map['waste_categories'] as Map<String, dynamic>?)?['name']
              as String? ??
          'Lainnya',
      weightKg: ((map['estimated_weight_kg'] as num?) ?? 0).toDouble(),
      estimatedGc: ((map['estimated_green_coin'] as num?) ?? 0).toInt(),
    );
  }
}
