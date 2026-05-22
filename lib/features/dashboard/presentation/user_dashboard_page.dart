import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/eco_logo.dart';
import '../../auth/providers/auth_provider.dart';
import '../../greencoin/models/greencoin_transaction.dart';
import '../../greencoin/providers/greencoin_provider.dart';
import '../models/dashboard_summary.dart';
import '../providers/dashboard_provider.dart';

class UserDashboardPage extends ConsumerWidget {
  const UserDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(name: user?.fullName.split(' ').first ?? 'User'),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  ref.invalidate(dashboardProvider);
                  ref.invalidate(greenCoinTransactionsProvider);
                  ref.invalidate(greenCoinBalanceProvider);
                  await ref.read(dashboardProvider.future);
                },
                child: dashboard.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(e.toString())),
                  data: (data) => _Body(data: data, fullName: user?.fullName),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.xl,
        AppSizes.md,
        AppSizes.xl,
        AppSizes.md,
      ),
      child: Row(
        children: [
          const EcoLogo(size: 36),
          const SizedBox(width: AppSizes.sm),
          const Text(
            'Beranda',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight, width: 2),
            ),
            child: const ClipOval(
              child: Icon(
                Icons.person_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final DashboardSummary data;
  final String? fullName;
  const _Body({required this.data, this.fullName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.xl,
        AppSizes.sm,
        AppSizes.xl,
        AppSizes.xxl,
      ),
      children: [
        MotionFadeSlide(
          delayMs: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${fullName?.split(' ').first ?? 'User'}! 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Mari buat bumi lebih hijau hari ini.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        MotionFadeSlide(
          delayMs: 90,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSizes.md,
            crossAxisSpacing: AppSizes.md,
            childAspectRatio: 1.45,
            children: [
              _MetricCard(
                icon: Icons.account_balance_wallet_outlined,
                assetPath: AppIcons.coin,
                iconBg: AppColors.primaryLight,
                iconColor: AppColors.primaryDark,
                label: 'SALDO GREENCOIN',
                value: Formatters.greenCoin(data.greenCoinBalance),
              ),
              _MetricCard(
                icon: Icons.delete_outline_rounded,
                assetPath: AppIcons.recycleBin,
                iconBg: const Color(0xFFE0F2FE),
                iconColor: const Color(0xFF0284C7),
                label: 'TOTAL SAMPAH',
                value: Formatters.weight(data.totalWasteKg),
              ),
              _MetricCard(
                icon: Icons.receipt_long_outlined,
                assetPath: AppIcons.grocery,
                iconBg: const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFEA580C),
                label: 'TOTAL TRANSAKSI',
                value: '${data.totalTransactions}',
              ),
              _MetricCard(
                icon: Icons.co2_outlined,
                iconBg: AppColors.primaryLight,
                iconColor: AppColors.primaryDark,
                label: 'CO2 DIHEMAT',
                value: Formatters.weight(data.co2SavedKg),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        MotionFadeSlide(
          delayMs: 160,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Aktivitas Daur Ulang',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '7 Hari Terakhir',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Icon(
                            Icons.expand_more,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                SizedBox(
                  height: 160,
                  child: _WeeklyChart(weights: data.weeklyWeights),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        MotionFadeSlide(
          delayMs: 230,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kategori Sampah',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                if (data.categoryShares.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                    child: Text(
                      'Belum ada data kategori. Mulai setor sampah\nlewat EcoPick atau EcoDrop.',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  )
                else
                  ...data.categoryShares.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.md),
                        child: _CategoryBar(share: c),
                      )),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        MotionFadeSlide(
          delayMs: 300,
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Transaksi Terbaru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/status'),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              _RecentTransactionsList(),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentTransactionsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(greenCoinTransactionsProvider);
    return txnsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSizes.lg),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const AppCard(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.lg,
          vertical: AppSizes.lg,
        ),
        child: Text(
          'Gagal memuat transaksi terbaru',
          style: TextStyle(color: AppColors.textTertiary),
        ),
      ),
      data: (txns) {
        if (txns.isEmpty) {
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
                  'Buat permintaan EcoPick atau setor EcoDrop\nuntuk mulai menabung GreenCoin.',
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
        final top = txns.take(3).toList();
        return Column(
          children: [
            for (var i = 0; i < top.length; i++) ...[
              MotionFadeSlide(
                delayMs: 80 * i,
                child: _RecentTxnTile(txn: top[i]),
              ),
              if (i < top.length - 1) const SizedBox(height: AppSizes.sm),
            ],
          ],
        );
      },
    );
  }
}

class _RecentTxnTile extends StatelessWidget {
  final GreenCoinTransaction txn;
  const _RecentTxnTile({required this.txn});

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
    final amount =
        '${txn.isInflow ? '+' : ''}${Formatters.greenCoin(txn.amountGc.abs())}';
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
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  Formatters.dateTime(txn.createdAt),
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
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: txn.isInflow
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                txn.status.toUpperCase(),
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

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String? assetPath;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              padding: const EdgeInsets.all(4),
              child: assetPath != null
                  ? Image.asset(
                      assetPath!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(icon, size: 18, color: iconColor),
                    )
                  : Icon(icon, size: 18, color: iconColor),
            ),
          ),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          _AnimatedMetricValue(value: value),
        ],
      ),
    );
  }
}

/// Animates the metric value with a numeric count-up effect if the value
/// contains a leading number (e.g. "2.500 GC", "45 kg", "12", "15.2 kg").
/// Falls back to plain text when no number can be parsed.
class _AnimatedMetricValue extends StatelessWidget {
  final String value;

  const _AnimatedMetricValue({required this.value});

  @override
  Widget build(BuildContext context) {
    final match = RegExp(r'^([\d\.,]+)(.*)$').firstMatch(value.trim());
    if (match == null) {
      return Text(
        value,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      );
    }
    final numStr = match.group(1)!;
    final suffix = match.group(2) ?? '';
    final target = double.tryParse(
          numStr.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;
    final isInteger = !numStr.contains(',') && !numStr.contains('.') ||
        target == target.truncate();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        final display = isInteger
            ? Formatters.compactNumber(animated.round())
            : animated.toStringAsFixed(1).replaceAll('.', ',');
        return Text(
          '$display$suffix',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        );
      },
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<double> weights;
  const _WeeklyChart({required this.weights});

  @override
  Widget build(BuildContext context) {
    final maxVal = weights.isEmpty
        ? 0.0
        : weights.reduce((a, b) => a > b ? a : b);
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final hasData = maxVal > 0;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: hasData ? maxVal * 1.35 : 8,
        barTouchData: BarTouchData(
          enabled: false,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.primary,
            tooltipRoundedRadius: AppSizes.radiusPill,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            tooltipMargin: 6,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final value = rod.toY;
              final label = value == value.truncate()
                  ? '${value.toInt()}kg'
                  : '${value.toStringAsFixed(1)}kg';
              return BarTooltipItem(
                label,
                const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              );
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= days.length) return const SizedBox();
                final isMax = hasData && weights[idx] == maxVal;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    days[idx],
                    style: TextStyle(
                      fontSize: 11,
                      color: isMax ? AppColors.primary : AppColors.textTertiary,
                      fontWeight: isMax ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(weights.length, (i) {
          final value = weights[i];
          final isMax = hasData && value == maxVal;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value <= 0 ? 0.3 : value,
                width: 24,
                color: isMax ? AppColors.primary : AppColors.primaryLight,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
            ],
            showingTooltipIndicators: isMax ? [0] : const [],
          );
        }),
      ),
      swapAnimationDuration: const Duration(milliseconds: 700),
      swapAnimationCurve: Curves.easeOutCubic,
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final CategoryShare share;
  const _CategoryBar({required this.share});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              share.name,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              '${(share.percent * 100).round()}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: share.percent),
          duration: AppMotion.slow,
          curve: AppMotion.curve,
          builder: (context, value, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              child: LinearProgressIndicator(
                value: AppMotion.reduce(context) ? share.percent : value,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(Color(share.color)),
              ),
            );
          },
        ),
      ],
    );
  }
}
