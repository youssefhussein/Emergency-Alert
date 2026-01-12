import 'package:emergency_alert/screens/drawer/app_drawer.dart';
import 'package:emergency_alert/screens/profile/contacts/contacts_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// gives access to themeController

import '../../services/emergency_service.dart';
import '../../services/profile_service.dart';
import '../../services/emergency_request_service.dart';
import 'emergency_detail_screen.dart';
import 'share_location_screen.dart';
import 'emergency_chat_screen.dart';

import 'package:emergency_alert/screens/profile/profile_screen.dart';

class EmergencyListScreen extends StatelessWidget {
  const EmergencyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestService = EmergencyRequestService(Supabase.instance.client);
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // ✅ SIMPLE modern theme tweaks (dark-mode safe)
    final bannerColor = isDark ? c.errorContainer : c.error;
    final bannerTextColor = isDark ? c.onErrorContainer : c.onError;

    final infoBoxColor = isDark
        ? c.tertiaryContainer.withOpacity(0.35)
        : c.tertiaryContainer.withOpacity(0.55);
    final infoBoxTextColor = c.onTertiaryContainer;

    final actionTileColor = c.surfaceContainerHighest;
    final actionTileForeground = c.onSurface;

    final sosBorderColor = isDark ? c.outlineVariant : c.surface;
    final sosShadowColor = c.error.withOpacity(isDark ? 0.28 : 0.42);

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        titleSpacing: 12, // ✅ a bit more “premium”
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Emergency Services',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.outlineVariant.withOpacity(0.6)),
        ),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
          children: [
            FutureBuilder(
              future: ProfileService(
                Supabase.instance.client,
              ).getCurrentUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text(
                    'Hello...',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }
                final profile = snapshot.data;
                final name =
                    (profile != null &&
                        profile.fullName != null &&
                        profile.fullName!.trim().isNotEmpty)
                    ? profile.fullName!.split(' ').first
                    : 'there';
                return Text(
                  'Hello, $name',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // ✅ Banner: softer in dark mode + modern radius + subtle border
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: bannerColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? c.error.withOpacity(0.35)
                      : Colors.transparent,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: bannerTextColor),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Emergency Access',
                        style: TextStyle(
                          color: bannerTextColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tap SOS below to get immediate assistance',
                    style: TextStyle(color: bannerTextColor.withOpacity(0.95)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ✅ SOS: keep your look, but more “alive” with a ring + cleaner gradient
            Center(
              child: GestureDetector(
                onTap: () {
                  final service = emergencyServices.first;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmergencyDetailScreen(service: service),
                    ),
                  );
                },
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: sosShadowColor,
                        blurRadius: 40,
                        spreadRadius: 8,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(5), // ✅ outer ring
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.surfaceContainerHighest,
                      border: Border.all(color: sosBorderColor, width: 0.8),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: isDark
                              ? [
                                  c.errorContainer,
                                  c.error.withOpacity(0.95),
                                  c.error,
                                ]
                              : [
                                  Colors.redAccent.shade700,
                                  const Color.fromARGB(255, 177, 18, 18),
                                  Colors.red.shade200,
                                ],
                          center: Alignment.center,
                          radius: 0.95,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          'SOS',
                          style: TextStyle(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                            shadows: const [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              'Quick Actions',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),

            _actionTile(
              context,
              icon: Icons.location_on_rounded,
              title: 'Share Location',
              subtitle: 'Send your location to emergency services',
              color: actionTileColor,
              foreground: actionTileForeground,
              onTap: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => const ShareLocationScreen(),
                //   ),
                // );
              },
            ),
            const SizedBox(height: 10),
            _actionTile(
              context,
              icon: Icons.phone_in_talk_rounded,
              title: 'Emergency Contacts',
              subtitle: 'Manage your emergency contact list',
              color: actionTileColor,
              foreground: actionTileForeground,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactsScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _actionTile(
              context,
              icon: Icons.headset_mic_rounded,
              title: 'Want assist?',
              subtitle: 'Chat with us to find the right support',
              color: const Color(0xFF8B5CFF),
              foreground: Colors.white,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmergencyChatScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // ✅ Info box: no hardcoded green, adapts to dark mode
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: infoBoxColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.outlineVariant.withOpacity(0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✓ Help is available 24/7',
                    style: TextStyle(
                      color: infoBoxTextColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "✓ Take a deep breath – you're safe",
                    style: TextStyle(
                      color: infoBoxTextColor.withOpacity(0.95),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color color = Colors.white,
    Color foreground = Colors.black87,
  }) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18), // ✅ slightly more modern
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: c.outlineVariant.withOpacity(0.6),
            ), // ✅ subtle border
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: foreground.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: foreground),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: foreground.withOpacity(0.80),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: foreground),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final EmergencyService service;
  final VoidCallback onTap;

  const _EmergencyCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: service.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white,
                child: Icon(service.icon, color: service.iconColor),
              ),
              const Spacer(),
              Text(
                service.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                service.number,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
