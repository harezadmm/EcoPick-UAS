import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';

class EcoLogo extends StatelessWidget {
  final double size;
  final bool dark;

  const EcoLogo({super.key, this.size = 32, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? Colors.white : AppColors.primaryLight,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      padding: EdgeInsets.all(size * 0.12),
      child: Image.asset(
        AppIcons.ecoBag,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.eco_rounded,
          size: size * 0.6,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
