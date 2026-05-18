class WasteCategory {
  final String id;
  final String name;
  final int greenCoinPerKg;
  final bool isActive;

  const WasteCategory({
    required this.id,
    required this.name,
    required this.greenCoinPerKg,
    this.isActive = true,
  });

  factory WasteCategory.fromMap(Map<String, dynamic> map) => WasteCategory(
        id: map['id'] as String,
        name: map['name'] as String,
        greenCoinPerKg: map['green_coin_per_kg'] as int,
        isActive: map['is_active'] as bool? ?? true,
      );

  static const defaults = <WasteCategory>[
    WasteCategory(id: 'besi', name: 'Besi', greenCoinPerKg: 400),
    WasteCategory(id: 'plastik', name: 'Plastik & Botol', greenCoinPerKg: 200),
    WasteCategory(id: 'elektronik', name: 'Elektronik', greenCoinPerKg: 500),
    WasteCategory(id: 'kaca', name: 'Kaca', greenCoinPerKg: 300),
    WasteCategory(id: 'kardus', name: 'Kardus', greenCoinPerKg: 150),
    WasteCategory(id: 'kertas', name: 'Kertas', greenCoinPerKg: 150),
    WasteCategory(id: 'logam', name: 'Logam', greenCoinPerKg: 400),
  ];
}
