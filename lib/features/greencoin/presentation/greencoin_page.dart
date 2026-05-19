import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/greencoin_transaction.dart';
import '../providers/greencoin_provider.dart';
import 'withdraw_bottom_sheet.dart';

class GreenCoinPage extends ConsumerStatefulWidget {
  const GreenCoinPage({super.key});

  @override
  ConsumerState<GreenCoinPage> createState() => _GreenCoinPageState();
}

class _GreenCoinPageState extends ConsumerState<GreenCoinPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final balance = user?.greenCoinBalance ?? 0;
    final rupiah = Formatters.rupiahFromGc(balance);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('GreenCoin'),
      ),
      body: SafeArea(
        child: MotionFadeSlide(
          delayMs: 40,
          child: ListView(
            padding: const EdgeInsets.all(AppSizes.xl),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.xl),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total Saldo',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: Image.asset(
                            AppIcons.wallet,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.account_balance_wallet_outlined,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.greenCoin(balance),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      '≈ ${Formatters.rupiah(rupiah)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up,
                              size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            '+12% bulan ini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () =>
                            WithdrawBottomSheet.show(context, balance),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusPill),
                          ),
                        ),
                        child: const Text(
                          'Tarik Dana',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.md),
              _SegmentTabs(
                index: _tabIndex,
                onChange: (i) => setState(() => _tabIndex = i),
                labels: const ['Semua', 'Masuk', 'Keluar'],
              ),
              const SizedBox(height: AppSizes.md),
              _TransactionList(filterIndex: _tabIndex),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionList extends ConsumerWidget {
  final int filterIndex;
  const _TransactionList({required this.filterIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(greenCoinTransactionsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
        child: Text('Gagal memuat transaksi: $e'),
      ),
      data: (txns) {
        final filtered = switch (filterIndex) {
          1 => txns.where((t) => t.isInflow).toList(),
          2 => txns.where((t) => !t.isInflow).toList(),
          _ => txns,
        };
        if (filtered.isEmpty) {
          return const AppCard(
            padding: EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.xl,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 32,
                  color: AppColors.textTertiary,
                ),
                SizedBox(height: AppSizes.sm),
                Text(
                  'Belum ada transaksi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Riwayat GreenCoin akan muncul setelah\nAnda mulai bertransaksi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          children: [
            for (final t in filtered) ...[
              _TransactionRow(txn: t),
              const SizedBox(height: AppSizes.sm),
            ],
          ],
        );
      },
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final GreenCoinTransaction txn;
  const _TransactionRow({required this.txn});

  @override
  Widget build(BuildContext context) {
    final (icon, title, iconBg, iconColor) = switch (txn.sourceType) {
      'ecopick' => (
          Icons.local_shipping_rounded,
          'EcoPick',
          AppColors.primaryLight,
          AppColors.primary,
        ),
      'ecodrop' => (
          Icons.location_on_rounded,
          'EcoDrop',
          AppColors.primaryLight,
          AppColors.primary,
        ),
      'withdraw' => (
          Icons.account_balance_wallet_outlined,
          'Tarik Dana',
          const Color(0xFFFFEDD5),
          const Color(0xFFEA580C),
        ),
      'marketplace' => (
          Icons.shopping_bag_outlined,
          'Marketplace',
          const Color(0xFFDBEAFE),
          const Color(0xFF1D4ED8),
        ),
      _ => (
          Icons.swap_horiz_rounded,
          'Penyesuaian',
          AppColors.surfaceMuted,
          AppColors.textSecondary,
        ),
    };
    return _TxnTile(
      icon: icon,
      iconBg: iconBg,
      iconColor: iconColor,
      title: title,
      date: Formatters.dateTime(txn.createdAt),
      amount:
          '${txn.isInflow ? '+' : ''}${Formatters.greenCoin(txn.amountGc.abs())}',
      positive: txn.isInflow,
      statusLabel: txn.status.toUpperCase(),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChange;
  final List<String> labels;

  const _SegmentTabs({
    required this.index,
    required this.onChange,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i == index;
        return Padding(
          padding: const EdgeInsets.only(right: AppSizes.sm),
          child: GestureDetector(
            onTap: () => onChange(i),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: active ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _TxnTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String date;
  final String amount;
  final bool positive;
  final String statusLabel;

  const _TxnTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.date,
    required this.amount,
    required this.positive,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.md,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: positive ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                statusLabel.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
