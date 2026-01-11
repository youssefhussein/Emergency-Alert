import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_state.dart';

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  static const _kLocation = 'settings_location_sharing';
  static const _kNotifs = 'settings_notifications_enabled';
  static const _kLang = 'settings_language_code';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      locationSharing: prefs.getBool(_kLocation) ?? state.locationSharing,
      notificationsEnabled:
          prefs.getBool(_kNotifs) ?? state.notificationsEnabled,
      languageCode: prefs.getString(_kLang) ?? state.languageCode,
    );
  }

  Future<void> setLocationSharing(bool v) async {
    state = state.copyWith(locationSharing: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLocation, v);
  }

  Future<void> setNotificationsEnabled(bool v) async {
    state = state.copyWith(notificationsEnabled: v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifs, v);
  }

  Future<void> setLanguageCode(String code) async {
    state = state.copyWith(languageCode: code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLang, code);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final notifier = SettingsNotifier();
    // fire-and-forget initial load
    Future.microtask(notifier.load);
    return notifier;
  },
);
