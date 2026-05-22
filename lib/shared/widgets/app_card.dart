import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import 'app_motion.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.radius = AppSizes.radiusLg,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: padding ?? const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: color ?? AppColors.surf(context),
        borderRadius: BorderRadius.circular(radius),
        border: border,
      ),
      child: child,
    );
    if (onTap != null) {
      return MotionPressable(
        enabled: true,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: content,
          ),
        ),
      );
    }
    return content;
  }
}
