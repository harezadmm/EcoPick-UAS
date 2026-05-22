import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController() : super(ThemeMode.light) {
    _load();
  }

  static const _key = 'ecopoin_theme_mode';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _key);
      state = switch (raw) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
    } catch (_) {
      state = ThemeMode.light;
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      await _storage.write(key: _key, value: mode.name);
    } catch (_) {/* ignore */}
  }

  Future<void> toggle() async {
    final next =
        state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await set(next);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController();
});
