class MarketplaceProduct {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String? emoji;
  final int priceGc;
  final int stock;
  final bool isActive;

  const MarketplaceProduct({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.emoji,
    required this.priceGc,
    required this.stock,
    this.isActive = true,
  });

  factory MarketplaceProduct.fromMap(Map<String, dynamic> map) {
    return MarketplaceProduct(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      emoji: map['emoji'] as String?,
      priceGc: map['price_gc'] as int? ?? 0,
      stock: map['stock'] as int? ?? 0,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  /// Resolved emoji to show in UI. Uses [emoji] when set, otherwise picks one
  /// based on keywords in [name], falling back to a generic shopping bag.
  String get displayEmoji {
    if (emoji != null && emoji!.trim().isNotEmpty) return emoji!.trim();
    final n = name.toLowerCase();
    if (n.contains('beras')) return '🍚';
    if (n.contains('minyak')) return '🛢️';
    if (n.contains('gula')) return '🍬';
    if (n.contains('garam')) return '🧂';
    if (n.contains('kopi')) return '☕';
    if (n.contains('teh')) return '🍵';
    if (n.contains('susu')) return '🥛';
    if (n.contains('telur')) return '🥚';
    if (n.contains('mie') || n.contains('mi instan') || n.contains('indom')) {
      return '🍜';
    }
    if (n.contains('detergen') || n.contains('pembersih pakaian')) return '🧺';
    if (n.contains('sabun cuci piring')) return '🍽️';
    if (n.contains('sabun')) return '🧼';
    if (n.contains('pasta gigi') || n.contains('odol')) return '🪥';
    if (n.contains('shampoo') || n.contains('sampo')) return '🧴';
    if (n.contains('tisu')) return '🧻';
    if (n.contains('plastik') || n.contains('kantong')) return '🛍️';
    if (n.contains('baterai')) return '🔋';
    if (n.contains('lampu')) return '💡';
    return '🛒';
  }

  static const demoList = <MarketplaceProduct>[
    MarketplaceProduct(
      id: 'p1',
      name: 'Beras 5 kg',
      description: 'Beras premium siap masak',
      priceGc: 2500,
      stock: 12,
      emoji: '🍚',
    ),
    MarketplaceProduct(
      id: 'p2',
      name: 'Minyak Goreng 2L',
      description: 'Minyak goreng bermerk',
      priceGc: 1800,
      stock: 8,
      emoji: '🛢️',
    ),
    MarketplaceProduct(
      id: 'p3',
      name: 'Detergen 1 kg',
      description: 'Detergen pembersih pakaian',
      priceGc: 900,
      stock: 24,
      emoji: '🧺',
    ),
    MarketplaceProduct(
      id: 'p4',
      name: 'Sabun Cuci Piring',
      description: 'Sabun cuci anti-bakteri',
      priceGc: 600,
      stock: 30,
      emoji: '🍽️',
    ),
  ];
}
