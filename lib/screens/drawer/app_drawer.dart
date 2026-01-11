import 'package:emergency_alert/screens/profile/medical/medical_info_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:emergency_alert/screens/emergency/emergency_list_screen.dart';
import 'package:emergency_alert/screens/emergency/share_location_screen.dart';
import 'package:emergency_alert/screens/profile/profile_screen.dart';
import 'package:emergency_alert/screens/profile/contacts/contacts_screen.dart';
import 'package:emergency_alert/screens/drawer/settings/settings_screen.dart';
import 'package:emergency_alert/screens/drawer/history/emergency_history_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/signup', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = Supabase.instance.client.auth.currentSession;
    final email = session?.user.email ?? 'Signed in';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.15,
                    ),
                    child: Icon(Icons.person, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Alert',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            _sectionTitle(context, 'Main'),
            _tile(
              context,
              icon: Icons.home_outlined,
              title: 'Home',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmergencyListScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
            _tile(
              context,
              icon: Icons.history,
              title: 'History',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmergencyHistoryScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 6),
            _sectionTitle(context, 'Account'),
            _tile(
              context,
              icon: Icons.person_outline,
              title: 'Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            _tile(
              context,
              icon: Icons.contacts_outlined,
              title: 'Contacts',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactsScreen()),
                );
              },
            ),
            _tile(
              context,
              icon: Icons.medical_information_outlined,
              title: 'Medical Info',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicalInfoScreen()),
                );
              },
            ),

            const SizedBox(height: 6),
            _sectionTitle(context, 'Tools'),
            _tile(
              context,
              icon: Icons.location_on_outlined,
              title: 'Share Location',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShareLocationScreen(),
                  ),
                );
              },
            ),
            _tile(
              context,
              icon: Icons.lock_outline,
              title: 'Permissions / Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),

            const Spacer(),
            const Divider(height: 1),

            _tile(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () => _logout(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.1,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title),
      horizontalTitleGap: 10,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      iconColor: theme.colorScheme.onSurface.withOpacity(0.8),
      onTap: onTap,
    );
  }
}
