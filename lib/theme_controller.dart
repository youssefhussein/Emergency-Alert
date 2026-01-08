
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  static const _key = 'theme_mode'; // 'system' | 'light' | 'dark'

  ThemeController(super.value);

  static Future<ThemeController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? 'system';

    final mode = switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return ThemeController(mode);
  }

  Future<void> _save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    await prefs.setString(_key, raw);
  }

  Future<void> setMode(ThemeMode mode) async {
    value = mode;
    await _save(mode);
  }

  Future<void> setDark(bool enabled) =>
      setMode(enabled ? ThemeMode.dark : ThemeMode.light);

  Future<void> setSystem() => setMode(ThemeMode.system);

  bool get isDark => value == ThemeMode.dark;
  bool get isLight => value == ThemeMode.light;
  bool get isSystem => value == ThemeMode.system;
}
