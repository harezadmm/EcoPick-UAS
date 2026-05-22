import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/status_badge.dart';

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Status Transaksi'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.xl,
                AppSizes.md,
                AppSizes.xl,
                AppSizes.sm,
              ),
              child: Row(
                children: List.generate(3, (i) {
                  final labels = ['Semua', 'Aktif', 'Selesai'];
                  final active = i == _tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSizes.sm),
                    child: MotionPressable(
                      onTap: () => setState(() => _tab = i),
                      child: AnimatedContainer(
                        duration: AppMotion.medium,
                        curve: AppMotion.curve,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg,
                          vertical: AppSizes.sm,
                        ),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                          border: Border.all(
                            color:
                                active ? AppColors.primary : AppColors.brd(context),
                          ),
                        ),
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            color:
                                active ? Colors.white : AppColors.textS(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.xl,
                  AppSizes.sm,
                  AppSizes.xl,
                  AppSizes.xl,
                ),
                children: const [
                  MotionFadeSlide(
                    delayMs: 40,
                    child: _StatusCard(
                      icon: Icons.local_shipping_rounded,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primaryLight,
                      type: 'EcoPick',
                      date: '24 Okt 2023 • 14:20',
                      category: 'Plastik & Botol',
                      weight: '5.2 kg',
                      estimatedGc: 150,
                      status: TransactionStatus.completed,
                    ),
                  ),
                  SizedBox(height: AppSizes.sm),
                  MotionFadeSlide(
                    delayMs: 90,
                    child: _StatusCard(
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primaryLight,
                      type: 'EcoDrop',
                      date: '22 Okt 2023 • 10:24',
                      category: 'Botol Plastik',
                      weight: '3.5 kg',
                      estimatedGc: 95,
                      status: TransactionStatus.process,
                    ),
                  ),
                  SizedBox(height: AppSizes.sm),
                  MotionFadeSlide(
                    delayMs: 140,
                    child: _StatusCard(
                      icon: Icons.local_shipping_rounded,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primaryLight,
                      type: 'EcoPick',
                      date: '20 Okt 2023 • 08:00',
                      category: 'Elektronik',
                      weight: '2.0 kg',
                      estimatedGc: 1000,
                      status: TransactionStatus.pending,
                    ),
                  ),
                  SizedBox(height: AppSizes.sm),
                  MotionFadeSlide(
                    delayMs: 190,
                    child: _StatusCard(
                      icon: Icons.location_on_rounded,
                      iconColor: AppColors.danger,
                      iconBg: AppColors.statusRejected,
                      type: 'EcoDrop',
                      date: '18 Okt 2023 • 11:45',
                      category: 'Kertas',
                      weight: '1.5 kg',
                      estimatedGc: 0,
                      status: TransactionStatus.rejected,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String type;
  final String date;
  final String category;
  final String weight;
  final int estimatedGc;
  final TransactionStatus status;

  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.type,
    required this.date,
    required this.category,
    required this.weight,
    required this.estimatedGc,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSizes.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textP(context),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textT(context),
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: status),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _kv(context, 'Kategori', category),
              ),
              Expanded(
                child: _kv(context, 'Berat', weight),
              ),
              if (estimatedGc > 0)
                Expanded(
                  child: _kv(context, 
                    'Estimasi',
                    '+$estimatedGc GC',
                    valueColor: AppColors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v, {Color? valueColor}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            k.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textT(context),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            v,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textP(context),
            ),
          ),
        ],
      );
}
