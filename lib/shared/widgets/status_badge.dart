import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';

class StatusBadge extends StatelessWidget {
  final TransactionStatus status;
  final String? customLabel;

  const StatusBadge({super.key, required this.status, this.customLabel});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Text(
        (customLabel ?? status.label).toUpperCase(),
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  (Color, Color) _colors(TransactionStatus s) {
    switch (s) {
      case TransactionStatus.pending:
        return (AppColors.statusPending, AppColors.statusPendingText);
      case TransactionStatus.process:
      case TransactionStatus.verified:
        return (AppColors.statusProcess, AppColors.statusProcessText);
      case TransactionStatus.completed:
        return (AppColors.statusCompleted, AppColors.statusCompletedText);
      case TransactionStatus.rejected:
      case TransactionStatus.cancelled:
        return (AppColors.statusRejected, AppColors.statusRejectedText);
    }
  }
}
