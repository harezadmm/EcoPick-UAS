class DashboardSummary {
  final int greenCoinBalance;
  final double totalWasteKg;
  final int totalTransactions;
  final double co2SavedKg;
  final List<double> weeklyWeights;
  final List<CategoryShare> categoryShares;

  const DashboardSummary({
    required this.greenCoinBalance,
    required this.totalWasteKg,
    required this.totalTransactions,
    required this.co2SavedKg,
    required this.weeklyWeights,
    required this.categoryShares,
  });

  static const empty = DashboardSummary(
    greenCoinBalance: 0,
    totalWasteKg: 0,
    totalTransactions: 0,
    co2SavedKg: 0,
    weeklyWeights: [0, 0, 0, 0, 0, 0, 0],
    categoryShares: [],
  );

  static const demo = DashboardSummary(
    greenCoinBalance: 2500,
    totalWasteKg: 45,
    totalTransactions: 12,
    co2SavedKg: 15.2,
    weeklyWeights: [4, 6, 3.5, 7, 4.5, 5, 8],
    categoryShares: [
      CategoryShare(name: 'Plastik', percent: 0.45, color: 0xFF22C55E),
      CategoryShare(name: 'Kertas', percent: 0.25, color: 0xFF3B82F6),
      CategoryShare(name: 'Organik', percent: 0.15, color: 0xFFF59E0B),
      CategoryShare(name: 'Lainnya', percent: 0.15, color: 0xFF9CA3AF),
    ],
  );
}

class CategoryShare {
  final String name;
  final double percent;
  final int color;

  const CategoryShare({
    required this.name,
    required this.percent,
    required this.color,
  });
}
