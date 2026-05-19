/// Centralized asset paths for raster icons in the EcoPoin app.
///
/// Source PNGs live in `ICON/` (3000x3000 high-res, gitignored), the build
/// uses the 512px versions under `assets/icons/`.
class AppIcons {
  AppIcons._();

  // Branding
  static const String ecoBag = 'assets/icons/eco-bag.png';

  // GreenCoin
  static const String coin = 'assets/icons/coin.png';
  static const String wallet = 'assets/icons/wallet.png';

  // Services
  static const String garbageTruck = 'assets/icons/garbage-truck.png';
  static const String recycleBin = 'assets/icons/recycle-bin.png';
  static const String trashMail = 'assets/icons/trash-mail.png';

  // Marketplace
  static const String grocery = 'assets/icons/grocery.png';

  // Waste categories
  static const String plasticBottle = 'assets/icons/recycle-plastic-bottle.png';
  static const String cardboardBox = 'assets/icons/cardboard-box.png';

  // Marketplace products
  static const String riceSack = 'assets/icons/rice-sack.png';
  static const String vegetableOil = 'assets/icons/vegetable-oil.png';
  static const String detergentPowder = 'assets/icons/detergent-powder.png';

  /// Pick a product asset path based on the product name. Returns `null` when
  /// no keyword matches; UI should fall back to emoji or generic icon.
  static String? forProductName(String name) {
    final n = name.toLowerCase();
    if (n.contains('beras') || n.contains('rice')) return riceSack;
    if (n.contains('minyak') || n.contains('oil')) return vegetableOil;
    if (n.contains('detergen')) return detergentPowder;
    if (n.contains('sabun')) return detergentPowder; // closest match
    if (n.contains('kardus') || n.contains('cardboard')) return cardboardBox;
    if (n.contains('plastik') || n.contains('botol')) return plasticBottle;
    return null;
  }

  /// Asset path for a waste category by name.
  static String? forWasteCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('plastik')) return plasticBottle;
    if (n.contains('kardus')) return cardboardBox;
    return null;
  }
}
