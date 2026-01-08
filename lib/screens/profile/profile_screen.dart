import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/user_profile.dart';
import '../../services/profile_service.dart';

import 'edit_profile_screen.dart';
import 'contacts_screen.dart';
import 'people_who_added_me_screen.dart';

import 'package:emergency_alert/screens/auth/login.dart';
import '../../main.dart';

import 'package:emergency_alert/widgets/profile/profile_header_card.dart';
import 'package:emergency_alert/widgets/profile/profile_menu_item.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileService _profileService;

  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  final Map<String, String> _statusLabels = {
    'safe': 'Safe',
    'need_help': 'Need Help',
    'at_hospital': 'At Hospital',
    'in_danger': 'In Danger',
    'unavailable': 'Unavailable',
  };

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(Supabase.instance.client);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final p = await _profileService.getCurrentUserProfile();
      setState(() => _profile = p);
    } catch (e) {
      setState(() => _error = 'Failed to load profile: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final name = _profile?.fullName ?? 'Unknown user';
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? 'No email';
    final avatarUrl = _profile?.profileImageUrl;
    final status = _profile?.profileStatus ?? 'safe';

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
            ],

            ProfileHeaderCard(
              name: name,
              email: email,
              avatarUrl: avatarUrl,
              status: status,
              statusLabels: _statusLabels,
              onEdit: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                ).then((_) => _loadProfile());
              },
            ),

            const SizedBox(height: 24),

            Text(
              'User information',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  ProfileMenuItem(
                    icon: Icons.person_outline,
                    title: 'Emergency Info',
                    subtitle: 'Name, age, gender, status, medical info',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      ).then((_) => _loadProfile());
                    },
                  ),
                  const Divider(height: 0),
                  ProfileMenuItem(
                    icon: Icons.contacts_outlined,
                    title: 'Emergency Contacts',
                    subtitle: 'People you rely on in emergencies',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ContactsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 0),
                  ProfileMenuItem(
                    icon: Icons.group_outlined,
                    title: 'People Who Added Me',
                    subtitle: 'Users who saved you as contact',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PeopleWhoAddedMeScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'App',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withOpacity(0.08),
                      ),
                      child: Icon(
                        Icons.dark_mode_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      'Dark Mode',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      themeController.isSystem
                          ? 'System default'
                          : (themeController.isDark ? 'Enabled' : 'Disabled'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    trailing: Switch(
                      value: themeController.isDark,
                      onChanged: (v) {
                        setState(() => themeController.setDark(v));
                      },
                    ),
                    onLongPress: () {
                      setState(() => themeController.setSystem());
                    },
                  ),
                  const Divider(height: 0),
                  ProfileMenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notification Settings',
                    subtitle: 'Control emergency alerts',
                    onTap: () {},
                  ),
                  const Divider(height: 0),
                  ProfileMenuItem(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'Change app language',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            FilledButton.tonal(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              child: const Text('Log out'),
            ),

            const SizedBox(height: 16),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      title: const Text('Delete profile?'),
                      content: const Text(
                        'This will delete your emergency profile data and sign you out.\n\n'
                        'You will not be able to use the emergency features until you sign up again.\n\n'
                        'Are you sure you want to continue?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );

                if (confirmed != true) return;

                try {
                  await _profileService.deleteCurrentUserProfile();
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Profile deleted successfully"),
                    ),
                  );

                  await Supabase.instance.client.auth.signOut();
                  if (!mounted) return;

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Delete failed: $e")),
                    );
                  }
                }
              },
              child: const Text("Delete Profile"),
            ),
          ],
        ),
      ),
    );
  }
}
