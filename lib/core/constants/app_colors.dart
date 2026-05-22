import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ---- Brand (same in both themes) ----
  static const Color primary = Color(0xFF22C55E);
  static const Color primaryDark = Color(0xFF16A34A);
  static const Color primaryLight = Color(0xFFDCFCE7);
  static const Color primarySubtle = Color(0xFFF0FDF4);

  // ---- Light palette ----
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF3F4F6);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF1F5F9);

  // ---- Dark palette ----
  static const Color backgroundDark = Color(0xFF0B0F14);
  static const Color surfaceDark = Color(0xFF161B22);
  static const Color surfaceMutedDark = Color(0xFF1F262E);
  static const Color primaryLightDark = Color(0xFF11321F);
  static const Color primarySubtleDark = Color(0xFF0E2418);

  static const Color textPrimaryDark = Color(0xFFE6E8EB);
  static const Color textSecondaryDark = Color(0xFFA0A6AC);
  static const Color textTertiaryDark = Color(0xFF6B737B);

  static const Color borderDark = Color(0xFF2A323B);
  static const Color dividerDark = Color(0xFF222A33);

  // ---- Status ----
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color statusPending = Color(0xFFFEF3C7);
  static const Color statusPendingText = Color(0xFFB45309);
  static const Color statusProcess = Color(0xFFDBEAFE);
  static const Color statusProcessText = Color(0xFF1D4ED8);
  static const Color statusCompleted = Color(0xFFDCFCE7);
  static const Color statusCompletedText = Color(0xFF15803D);
  static const Color statusRejected = Color(0xFFFEE2E2);
  static const Color statusRejectedText = Color(0xFFB91C1C);

  // ---- Context-aware accessors ----
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext c) => isDark(c) ? backgroundDark : background;
  static Color surf(BuildContext c) => isDark(c) ? surfaceDark : surface;
  static Color surfMuted(BuildContext c) =>
      isDark(c) ? surfaceMutedDark : surfaceMuted;
  static Color primaryTint(BuildContext c) =>
      isDark(c) ? primaryLightDark : primaryLight;
  static Color primarySubtleColor(BuildContext c) =>
      isDark(c) ? primarySubtleDark : primarySubtle;
  static Color textP(BuildContext c) =>
      isDark(c) ? textPrimaryDark : textPrimary;
  static Color textS(BuildContext c) =>
      isDark(c) ? textSecondaryDark : textSecondary;
  static Color textT(BuildContext c) =>
      isDark(c) ? textTertiaryDark : textTertiary;
  static Color brd(BuildContext c) => isDark(c) ? borderDark : border;
  static Color div(BuildContext c) => isDark(c) ? dividerDark : divider;
}
