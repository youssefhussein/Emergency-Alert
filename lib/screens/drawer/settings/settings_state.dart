class SettingsState {
  final bool locationSharing;
  final bool notificationsEnabled;
  final String languageCode; // e.g. 'en', 'ar'

  const SettingsState({
    this.locationSharing = true,
    this.notificationsEnabled = true,
    this.languageCode = 'en',
  });

  SettingsState copyWith({
    bool? locationSharing,
    bool? notificationsEnabled,
    String? languageCode,
  }) {
    return SettingsState(
      locationSharing: locationSharing ?? this.locationSharing,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}
