import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/marketplace_service.dart';
import '../models/marketplace_product.dart';

final marketplaceServiceProvider =
    Provider<MarketplaceService>((ref) => MarketplaceService());

final marketplaceProductsProvider =
    FutureProvider<List<MarketplaceProduct>>((ref) async {
  return ref.read(marketplaceServiceProvider).fetchProducts();
});
