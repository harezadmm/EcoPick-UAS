import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class SuccessHeader extends StatelessWidget {
  final IconData icon;
  final String? assetPath;
  final String title;
  final String subtitle;
  final Color iconColor;

  const SuccessHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.assetPath,
    this.iconColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: assetPath != null
                  ? Image.asset(
                      assetPath!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          Icon(icon, color: iconColor, size: 40),
                    )
                  : Icon(icon, color: iconColor, size: 40),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.lg),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
