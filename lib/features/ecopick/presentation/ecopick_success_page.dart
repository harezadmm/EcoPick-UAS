import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/success_header.dart';
import '../../../core/constants/app_strings.dart';

class EcoPickSuccessPage extends StatelessWidget {
  const EcoPickSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.xl),
          children: [
            const SizedBox(height: AppSizes.xxl),
            const SuccessHeader(
              icon: Icons.local_shipping_rounded,
              assetPath: AppIcons.garbageTruck,
              title: 'EcoPick Terkirim',
              subtitle:
                  'Permintaan penjemputan Anda telah kami terima dan menunggu persetujuan admin sebelum GreenCoin masuk.',
            ),
            const SizedBox(height: AppSizes.xl),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Ringkasan\npenjemputan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textP(context),
                        ),
                      ),
                      Spacer(),
                      StatusBadge(
                        status: TransactionStatus.pending,
                        customLabel: 'MENUNGGU PENJEMPUTAN',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _RowItem(
                    label: 'Tanggal & Waktu',
                    value: 'Rabu, 12 Juni 2026 • 08:00',
                    icon: Icons.calendar_today_outlined,
                  ),
                  _RowItem(
                    label: 'Lokasi',
                    value: 'Jl. Pemuda No. 12, Surabaya',
                    icon: Icons.location_on_outlined,
                  ),
                  Divider(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KATEGORI',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textT(context),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Plastik & Kertas',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textP(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ESTIMASI BERAT',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textT(context),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '5.2 kg',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textP(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.lg,
                      vertical: AppSizes.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.savings_outlined,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: AppSizes.sm),
                        Text(
                          'Estimasi GreenCoin',
                          style: TextStyle(
                            color: AppColors.textS(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '+150 GC',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Center(
                    child: Text(
                      'Nomor Referensi: EPK-260612-0182',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textT(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.primarySubtle,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                border: const Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text(
                        'Langkah selanjutnya',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textP(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  ..._steps.asMap().entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.sm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(top: 1),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${e.key + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.textS(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.xl),
            SecondaryButton(
              label: 'Kembali ke beranda',
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    );
  }

  static const _steps = [
    'Pastikan sampah sudah dipilah sebelum petugas datang.',
    'Siapkan sampah 10–15 menit sebelum jadwal penjemputan.',
    'Admin akan menyetujui data setelah penjemputan selesai.',
    'GreenCoin masuk setelah status EcoPick disetujui admin.',
  ];
}

class _RowItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _RowItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textT(context)),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textT(context),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textP(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
