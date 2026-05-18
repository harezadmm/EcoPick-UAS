import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/success_header.dart';

class WithdrawSuccessPage extends StatelessWidget {
  const WithdrawSuccessPage({super.key});

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
              icon: Icons.account_balance_wallet_outlined,
              title: 'Tarik Dana Berhasil',
              subtitle:
                  'Permintaan pencairan GreenCoin Anda sedang diproses ke tujuan yang dipilih.',
            ),
            const SizedBox(height: AppSizes.xl),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text(
                        'Ringkasan penarikan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Spacer(),
                      StatusBadge(
                        status: TransactionStatus.process,
                        customLabel: 'DIPROSES',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _row(
                    'Jumlah ditarik',
                    '2,000 GC',
                    valueColor: AppColors.primary,
                  ),
                  _row('Nilai rupiah', 'Rp 200.000'),
                  _row('Tujuan pencairan', 'BCA •••• 4821'),
                  _row('Estimasi masuk', 'Maks. 1 x 24 jam'),
                  const Divider(height: 32),
                  _row(
                    'Sisa saldo',
                    '3,240 GC',
                  ),
                  _row(
                    'Nomor referensi',
                    'GWD-260612-0041',
                    valueColor: AppColors.textTertiary,
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
                  Row(
                    children: const [
                      Icon(Icons.info_outline,
                          color: AppColors.primary, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Informasi penting',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  ..._bullets.map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 7, right: 8),
                            child: CircleAvatar(
                              radius: 2.5,
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              b,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.5,
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

  Widget _row(String k, String v, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                k,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
            Text(
              v,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );

  static const _bullets = [
    'Dana akan dikirim ke rekening tujuan sesuai estimasi proses.',
    'Riwayat penarikan dapat dilihat pada halaman GreenCoin.',
    'Hubungi dukungan jika dana belum masuk setelah estimasi waktu berakhir.',
  ];
}
