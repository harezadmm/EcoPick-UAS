import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/success_header.dart';
import '../models/withdraw_request.dart';

class WithdrawSuccessPage extends StatelessWidget {
  final WithdrawRequest? request;
  const WithdrawSuccessPage({super.key, this.request});

  @override
  Widget build(BuildContext context) {
    // Helper baris tabel ringkasan
    Widget kv(String k, String v, {Color? valueColor}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  k,
                  style: TextStyle(color: AppColors.textS(context)),
                ),
              ),
              Text(
                v,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textP(context),
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.xl),
          children: [
            const SizedBox(height: AppSizes.xl),
            const SuccessHeader(
              icon: Icons.account_balance_wallet_outlined,
              assetPath: AppIcons.wallet,
              title: 'Permintaan Terkirim!',
              subtitle:
                  'Permintaan penarikan GreenCoin Anda sedang menunggu persetujuan admin. Saldo akan dikurangi setelah disetujui.',
            ),
            const SizedBox(height: AppSizes.xl),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Ringkasan penarikan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textP(context),
                        ),
                      ),
                      const Spacer(),
                      const StatusBadge(
                        status: TransactionStatus.pending,
                        customLabel: 'MENUNGGU REVIEW',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),
                  kv(
                    'Jumlah ditarik',
                    request != null
                        ? Formatters.greenCoin(request!.amountGc)
                        : '2,000 GC',
                    valueColor: AppColors.primary,
                  ),
                  kv(
                    'Nilai rupiah',
                    request != null
                        ? Formatters.rupiah(request!.amountRupiah)
                        : 'Rp 200.000',
                  ),
                  kv(
                    'Tujuan pencairan',
                    request?.maskedAccount ?? 'BCA •••• 4821',
                  ),
                  kv('Estimasi review', 'Maks. 1 x 24 jam'),
                  const Divider(height: 32),
                  kv(
                    'Saldo saat ini',
                    request != null
                        ? Formatters.greenCoin(
                            request!.remainingBalanceGc + request!.amountGc,
                          )
                        : '19,600 GC',
                  ),
                  kv(
                    'Nomor referensi',
                    'GWD-260612-0041',
                    valueColor: AppColors.textT(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.primarySubtleColor(context),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: AppColors.primary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Informasi penting',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textP(context),
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
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textS(context),
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

  static const _bullets = [
    'Saldo GreenCoin Anda BELUM berkurang — admin harus menyetujui dahulu.',
    'Setelah disetujui, saldo dikurangi dan dana dikirim ke e-wallet tujuan.',
    'Jika ditolak, permintaan dibatalkan dan saldo tetap utuh.',
    'Riwayat permintaan dapat dilihat pada halaman GreenCoin.',
  ];
}
