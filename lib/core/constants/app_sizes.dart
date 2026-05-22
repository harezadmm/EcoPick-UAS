import 'package:flutter/widgets.dart';

class AppSizes {
  AppSizes._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  static const double buttonHeight = 52;
  static const double inputHeight = 52;

  // ---- Responsive helpers ----

  /// Width in logical pixels at which we switch to "narrow" (phone) layouts.
  static const double narrowBreakpoint = 380;

  /// Width below which the screen is considered "very narrow".
  static const double tinyBreakpoint = 340;

  /// Comfortable horizontal padding for screen-level content. Smaller on phones
  /// so cards have more room to breathe.
  static double screenHorizontal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < tinyBreakpoint) return md;
    if (width < narrowBreakpoint) return lg;
    return xl;
  }

  /// Vertical breathing room at the top of scrolling screen content.
  static double screenVerticalTop(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width < narrowBreakpoint ? md : lg;
  }

  /// Inner padding for cards / panels on the current screen size.
  static double panelPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < tinyBreakpoint) return md;
    if (width < narrowBreakpoint) return md + 2; // 14
    return lg;
  }

  static bool isNarrow(BuildContext context) {
    return MediaQuery.sizeOf(context).width < narrowBreakpoint;
  }
}
