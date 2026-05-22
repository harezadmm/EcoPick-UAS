import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

class EcoPoinApp extends ConsumerWidget {
  const EcoPoinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // 600ms smooth crossfade between light/dark on toggle
      themeAnimationDuration: const Duration(milliseconds: 600),
      themeAnimationCurve: Curves.easeInOutCubic,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
