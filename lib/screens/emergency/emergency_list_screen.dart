import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// gives access to themeController

import '../../services/emergency_service.dart';
import '../../services/profile_service.dart';
import '../../services/emergency_request_service.dart';
import 'emergency_detail_screen.dart';
import 'share_location_screen.dart';
import 'emergency_chat_screen.dart';
import 'package:emergency_alert/screens/profile/contacts_screen.dart';
import 'package:emergency_alert/screens/profile/profile_screen.dart';

class EmergencyListScreen extends StatelessWidget {
  const EmergencyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final requestService = EmergencyRequestService(Supabase.instance.client);
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return Scaffold(
      // backgroundColor: const Color(0xFFF5F7FB),
      backgroundColor: c.surface,

      appBar: AppBar(
        // backgroundColor: Colors.white,
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        titleSpacing: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'Emergency Services',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder(
              future: ProfileService(
                Supabase.instance.client,
              ).getCurrentUserProfile(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Hello...');
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Red banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Quick Emergency Access',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tap SOS below to get immediate assistance',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Single circular SOS card
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
                    gradient: RadialGradient(
                      colors: [
                        Colors.redAccent.shade700,
                        Colors.redAccent,
                        Colors.red.shade200,
                      ],
                      center: Alignment.center,
                      radius: 0.95,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 8,
                        offset: Offset(0, 16),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 6),
                  ),
                  child: Center(
                    child: Text(
                      'SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        shadows: [
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

            const SizedBox(height: 24),

            const Text(
              'Quick Actions',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            _actionTile(
              context,
              icon: Icons.location_on_rounded,
              title: 'Share Location',
              subtitle: 'Send your location to emergency services',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShareLocationScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _actionTile(
              context,
              icon: Icons.phone_in_talk_rounded,
              title: 'Emergency Contacts',
              subtitle: 'Manage your emergency contact list',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // builder: (_) => const EmergencyContactsScreen(),
                    builder: (_) => const ContactsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _actionTile(
              context,
              icon: Icons.headset_mic_rounded,
              title: 'Need Help Choosing?',
              subtitle: 'Chat with us to find the right service',
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

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8FFF0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('✓ Help is available 24/7'),
                  Text('✓ Trained professionals are ready'),
                  Text("✓ Take a deep breath – you're safe"),
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
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: foreground.withOpacity(0.08),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: foreground.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: foreground),
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
