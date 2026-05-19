import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/success_header.dart';

class EcoDropSuccessPage extends StatelessWidget {
  const EcoDropSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.xl),
          children: [
            const SizedBox(height: AppSizes.xl),
            const SuccessHeader(
              icon: Icons.recycling_rounded,
              assetPath: AppIcons.recycleBin,
              title: 'EcoDrop Terkirim',
              subtitle:
                  'Data setoran Anda telah kami terima dan sedang menunggu persetujuan admin sebelum GreenCoin masuk.',
            ),
            const SizedBox(height: AppSizes.xl),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text(
                        'Ringkasan setoran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Spacer(),
                      StatusBadge(
                        status: TransactionStatus.pending,
                        customLabel: 'MENUNGGU VERIFIKASI',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _kv('Lokasi setor', 'Bank Sampah Induk\nSurabaya'),
                  _kv('Tanggal setor', 'Rabu, 12 Juni 2026'),
                  _kv('Waktu kirim', '10:24'),
                  const Divider(height: 32),
                  _kv('Kategori sampah', 'Botol plastik'),
                  _kv('Berat', '3.5 kg'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.sm,
                    ),
                    child: Row(
                      children: const [
                        Expanded(
                          child: Text(
                            'Foto bukti',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Terkirim',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
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
                      children: const [
                        Text(
                          'Estimasi GreenCoin',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        Text(
                          '+95 GC',
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
                  Row(
                    children: const [
                      Text(
                        'NOMOR REFERENSI',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'EDP-260612-0094',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Langkah selanjutnya',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
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
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${e.key + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.textSecondary,
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

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                k,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );

  static const _steps = [
    'Petugas akan memverifikasi data dan berat setoran Anda.',
    'GreenCoin akan masuk setelah admin menyetujui setoran.',
    'Anda dapat memantau status setoran di halaman EcoDrop.',
  ];
}
