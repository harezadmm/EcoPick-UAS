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
              child: dashboard.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (data) => _Body(data: data, fullName: user?.fullName),
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

class _Body extends StatelessWidget {
  final DashboardSummary data;
  final String? fullName;
  const _Body({required this.data, this.fullName});

  @override
  Widget build(BuildContext context) {
    return ListView(
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
                assetPath: AppIcons.ecoBag,
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
              if (data.totalTransactions == 0)
                const AppCard(
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
                ),
            ],
          ),
        ),
      ],
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
          Container(
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<double> weights;
  const _WeeklyChart({required this.weights});

  @override
  Widget build(BuildContext context) {
    final maxVal = weights.reduce((a, b) => a > b ? a : b);
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.3,
        barTouchData: BarTouchData(enabled: false),
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
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= days.length) return const SizedBox();
                final isMax = weights[idx] == maxVal;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    days[idx],
                    style: TextStyle(
                      fontSize: 11,
                      color: isMax ? AppColors.primary : AppColors.textTertiary,
                      fontWeight: isMax ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: List.generate(weights.length, (i) {
          final isMax = weights[i] == maxVal;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: weights[i],
                width: 22,
                color: isMax ? AppColors.primary : AppColors.primaryLight,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ],
            showingTooltipIndicators: isMax ? [0] : [],
          );
        }),
      ),
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
