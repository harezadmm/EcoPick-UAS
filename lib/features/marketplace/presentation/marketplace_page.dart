import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/success_confetti_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../greencoin/providers/greencoin_provider.dart';
import '../models/marketplace_product.dart';
import '../providers/marketplace_provider.dart';

class MarketplacePage extends ConsumerWidget {
  const MarketplacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final products = ref.watch(marketplaceProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        title: const Text('Marketplace'),
        centerTitle: false,
        titleSpacing: AppSizes.xl,
      ),
      body: SafeArea(
        child: products.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Gagal memuat produk: $e')),
          data: (list) => RefreshIndicator(
            onRefresh: () async => ref.refresh(marketplaceProductsProvider),
            child: ListView(
                padding: const EdgeInsets.all(AppSizes.xl),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saldo GreenCoin',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.greenCoin(
                                  user?.greenCoinBalance ?? 0,
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Text(
                    'Tukar GreenCoin',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textP(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih produk kebutuhan sehari-hari Anda',
                    style: TextStyle(color: AppColors.textS(context)),
                  ),
                  const SizedBox(height: AppSizes.md),
                  if (list.isEmpty)
                    AppCard(
                      padding: EdgeInsets.all(AppSizes.xl),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 36,
                            color: AppColors.textT(context),
                          ),
                          SizedBox(height: AppSizes.sm),
                          Text(
                            'Belum ada produk tersedia',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Admin belum menambahkan katalog\nmarketplace.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textT(context),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: list.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: AppSizes.md,
                        crossAxisSpacing: AppSizes.md,
                        mainAxisExtent: 290,
                      ),
                      itemBuilder: (context, i) => _ProductCard(
                        product: list[i],
                        currentBalance: user?.greenCoinBalance ?? 0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}

class _ProductCard extends ConsumerStatefulWidget {
  final MarketplaceProduct product;
  final int currentBalance;

  const _ProductCard({
    required this.product,
    required this.currentBalance,
  });

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  bool _busy = false;

  Future<void> _exchange() async {
    // Capture messenger BEFORE any await so we don't depend on this widget's
    // context after invalidate (which can dispose the card).
    final messenger = ScaffoldMessenger.of(context);
    final p = widget.product;

    void showMsg(String message) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }

    if (p.stock <= 0) {
      showMsg('Stok habis. Produk ini sedang tidak tersedia.');
      return;
    }
    if (widget.currentBalance < p.priceGc) {
      showMsg(
        'Anda butuh ${Formatters.greenCoin(p.priceGc)} untuk menukar produk ini.',
      );
      return;
    }

    final confirmed = await _showConfirmDialog(p);
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _busy = true);
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      await ref
          .read(marketplaceServiceProvider)
          .exchange(userId: user.id, product: p);

      // Update local balance + invalidate dependent providers.
      ref.read(currentUserProvider.notifier).state =
          user.copyWith(greenCoinBalance: user.greenCoinBalance - p.priceGc);
      ref.invalidate(marketplaceProductsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(greenCoinTransactionsProvider);
      ref.invalidate(greenCoinBalanceProvider);

      // Reset busy state so dialog button is responsive
      if (mounted) setState(() => _busy = false);

      // Show confetti + congrats dialog
      if (!mounted) return;
      await SuccessConfettiDialog.show(
        context,
        title: 'Selamat! 🎉',
        message:
            'Anda berhasil menukar ${p.name} dengan ${Formatters.greenCoin(p.priceGc)}.',
        emoji: p.displayEmoji,
        primaryActionLabel: 'Lanjutkan',
      );
      return;
    } catch (e) {
      showMsg('Gagal menukar barang: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _showConfirmDialog(MarketplaceProduct p) {
    final remaining = widget.currentBalance - p.priceGc;
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.xl,
            AppSizes.xl,
            AppSizes.xl,
            AppSizes.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    p.displayEmoji,
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Center(
                child: Text(
                  'Konfirmasi Penukaran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textP(context),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Center(
                child: Text(
                  'Tukar GreenCoin dengan produk berikut?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textS(context),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: AppColors.surfMuted(context),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Column(
                  children: [
                    _kv('Produk', p.name),
                    const SizedBox(height: 6),
                    _kv('Harga', Formatters.greenCoin(p.priceGc),
                        valueColor: AppColors.primary),
                    const Divider(height: 20),
                    _kv('Saldo saat ini',
                        Formatters.greenCoin(widget.currentBalance)),
                    const SizedBox(height: 6),
                    _kv('Sisa saldo', Formatters.greenCoin(remaining),
                        valueColor: AppColors.textP(context), bold: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        side: BorderSide(color: AppColors.brd(context)),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                      ),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          color: AppColors.textS(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                      ),
                      child: const Text(
                        'Tukar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String key, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            key,
            style: TextStyle(
              color: AppColors.textS(context),
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textP(context),
            fontSize: 13,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLg),
            ),
            child: Container(
              height: 100,
              color: AppColors.primarySubtle,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(AppSizes.sm),
              child: _ProductMedia(product: p),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textP(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textT(context),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    Formatters.greenCoin(p.priceGc),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Stok: ${p.stock}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textT(context),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _exchange,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Tukar',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductMedia extends StatelessWidget {
  final MarketplaceProduct product;
  const _ProductMedia({required this.product});

  @override
  Widget build(BuildContext context) {
    // 1. Remote image (admin-set URL) wins
    final url = product.imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    // 2. Local asset by product name
    final asset = AppIcons.forProductName(product.name);
    if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    // 3. Emoji fallback
    return _fallback();
  }

  Widget _fallback() => Text(
        product.displayEmoji,
        style: const TextStyle(fontSize: 48),
      );
}
