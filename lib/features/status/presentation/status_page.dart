import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/status_badge.dart';
import '../models/waste_request.dart';
import '../providers/status_provider.dart';

class StatusPage extends ConsumerStatefulWidget {
  const StatusPage({super.key});

  @override
  ConsumerState<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends ConsumerState<StatusPage> {
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
              child: ref.watch(userWasteRequestsProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text(err.toString())),
                data: (requests) {
                  // Filter based on tab
                  final filtered = requests.where((req) {
                    if (_tab == 0) return true; // Semua
                    if (_tab == 1) {
                      return req.status == TransactionStatus.pending ||
                          req.status == TransactionStatus.process;
                    } // Aktif
                    return req.status == TransactionStatus.completed ||
                        req.status == TransactionStatus.rejected ||
                        req.status == TransactionStatus.cancelled; // Selesai
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'Belum ada transaksi',
                        style: TextStyle(color: AppColors.textS(context)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.xl,
                      AppSizes.sm,
                      AppSizes.xl,
                      AppSizes.xl,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final req = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: MotionFadeSlide(
                          delayMs: (i * 50).clamp(0, 500),
                          child: _StatusCard(
                            icon: req.type == 'EcoPick'
                                ? Icons.local_shipping_rounded
                                : Icons.location_on_rounded,
                            iconColor: req.status == TransactionStatus.rejected || req.status == TransactionStatus.cancelled
                                ? AppColors.danger
                                : AppColors.primary,
                            iconBg: req.status == TransactionStatus.rejected || req.status == TransactionStatus.cancelled
                                ? AppColors.statusRejected
                                : AppColors.primaryLight,
                            type: req.type,
                            date: Formatters.dateTime(req.createdAt),
                            category: req.categoryName,
                            weight: Formatters.weight(req.weightKg),
                            estimatedGc: req.estimatedGc,
                            status: req.status,
                          ),
                        ),
                      );
                    },
                  );
                },
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
