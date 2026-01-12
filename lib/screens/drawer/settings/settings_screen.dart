import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../widgets/responsive_scaffold.dart';
import 'package:emergency_alert/widgets/responsive_scaffold.dart';
import 'package:emergency_alert/main.dart';

import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final s = ref.watch(settingsProvider);

    return ResponsiveScaffold(
      backgroundColor: cs.surface,
      padding: EdgeInsets.zero,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: const Text('Permissions & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Permissions',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          _switchCard(
            context,
            icon: Icons.location_on_outlined,
            title: 'Location sharing',
            subtitle:
                'Helps responders find you faster. You can disable this, but response time may increase.',
            value: s.locationSharing,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setLocationSharing(v),
          ),
          const SizedBox(height: 10),
          _switchCard(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle:
                'Receive updates about your emergency request status and responder assignment.',
            value: s.notificationsEnabled,
            onChanged: (v) =>
                ref.read(settingsProvider.notifier).setNotificationsEnabled(v),
          ),

          const SizedBox(height: 20),
          Text(
            'Appearance',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            elevation: 0,
            color: cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark mode'),
                  subtitle: Text(
                    themeController.isSystem
                        ? 'System default'
                        : (themeController.isDark ? 'Enabled' : 'Disabled'),
                  ),
                  trailing: Switch(
                    value: themeController.isDark,
                    onChanged: (v) => themeController.setDark(v),
                  ),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.phone_iphone_outlined),
                  title: const Text('Use system theme'),
                  subtitle: const Text('Let your phone control the theme.'),
                  trailing: Switch(
                    value: themeController.isSystem,
                    onChanged: (v) {
                      if (v) {
                        themeController.setSystem();
                      } else {
                        themeController.setDark(false);
                      }
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Language',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('App language'),
              subtitle: Text(s.languageCode == 'ar' ? 'Arabic' : 'English'),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: s.languageCode,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('EN')),
                    DropdownMenuItem(value: 'ar', child: Text('AR')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    ref.read(settingsProvider.notifier).setLanguageCode(v);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Language preference saved.'),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),
          Text(
            'Tip: settings are stored locally on this device.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle),
        secondary: Icon(icon, color: cs.primary),
      ),
    );
  }
}
