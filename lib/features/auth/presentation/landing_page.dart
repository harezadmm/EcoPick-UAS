import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../shared/widgets/eco_logo.dart';
import '../../../shared/widgets/primary_button.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xl,
                vertical: AppSizes.md,
              ),
              child: Row(
                children: [
                  const EcoLogo(size: 36),
                  const SizedBox(width: AppSizes.sm),
                  const Text(
                    'EcoPoin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Masuk'),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  ElevatedButton(
                    onPressed: () => context.push('/register'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(96, 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                      ),
                    ),
                    child: const Text('Daftar'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizes.xxl),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.lg,
                        vertical: AppSizes.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: AppColors.primaryDark,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'GERAKAN DAUR ULANG SURABAYA',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                        children: [
                          TextSpan(text: 'Ubah\nSampahmu Jadi\n'),
                          TextSpan(
                            text: 'GreenCoin',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.xl),
                    const Text(
                      'Mari berpartisipasi dalam menjaga lingkungan Surabaya tetap asri dan dapatkan imbalan menarik untuk setiap sampah yang Anda daur ulang secara bertanggung jawab.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxxl),
                    PrimaryButton(
                      label: 'Mulai Sekarang',
                      onPressed: () => context.push('/register'),
                    ),
                    const SizedBox(height: AppSizes.xxl),
                    Row(
                      children: [
                        SizedBox(
                          width: 76,
                          height: 32,
                          child: Stack(
                            children: List.generate(3, (i) {
                              const colors = [
                                Color(0xFFFEDBA8),
                                Color(0xFFB3D7FF),
                                Color(0xFFD8C5F5),
                              ];
                              return Positioned(
                                left: i * 22.0,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: colors[i],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.background,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        const Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '12k+ ',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(
                                  text: 'warga Surabaya telah\nbergabung',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
