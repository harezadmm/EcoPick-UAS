class GreenCoinTransaction {
  final String id;
  final String sourceType;
  final String transactionType;
  final int amountGc;
  final String status;
  final String? description;
  final DateTime createdAt;

  const GreenCoinTransaction({
    required this.id,
    required this.sourceType,
    required this.transactionType,
    required this.amountGc,
    required this.status,
    required this.createdAt,
    this.description,
  });

  factory GreenCoinTransaction.fromMap(Map<String, dynamic> map) {
    return GreenCoinTransaction(
      id: map['id'] as String,
      sourceType: map['source_type'] as String? ?? 'adjustment',
      transactionType: map['transaction_type'] as String? ?? 'earn',
      amountGc: map['amount_gc'] as int? ?? 0,
      status: map['status'] as String? ?? 'completed',
      description: map['description'] as String?,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  bool get isInflow => amountGc > 0;
}
