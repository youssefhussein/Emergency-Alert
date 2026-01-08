import 'package:flutter/material.dart';

import '../../services/emergency_service.dart';
import 'send_info_form_screen.dart';
import '../../main.dart'; // gives access to themeController

class EmergencyDetailScreen extends StatelessWidget {
  final EmergencyService service;

  const EmergencyDetailScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return Scaffold(
      // backgroundColor: const Color(0xFFF5F7FB),
      backgroundColor: c.background,

      appBar: AppBar(
        // backgroundColor: Colors.white,
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(service.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Reassurance banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8FFF0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite_border, color: Color(0xFF00C853)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service.reassuranceText,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Quick Actions',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          // Call now button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.call_rounded),
              label: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Call Now  ${service.number}'),
                  const Icon(Icons.arrow_forward_ios, size: 18),
                ],
              ),
              onPressed: () async {
                final uri = Uri(scheme: 'tel', path: service.number);
                // await launchUrl(uri);
              },
            ),
          ),

          const SizedBox(height: 10),

          // Send info first
          _whiteTile(
            context,
            icon: Icons.assignment_rounded,
            title: 'Send Information First',
            subtitle: 'Help us prepare for your emergency',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SendInfoFormScreen(service: service),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          _whiteTile(
            context,
            icon: Icons.phone_in_talk_rounded,
            title: 'Direct Line',
            subtitle: '(555) 456-7890',
            trailing: const Text('Call', style: TextStyle(color: Colors.blue)),
            onTap: () async {
              final uri = Uri(scheme: 'tel', path: '5554567890');
              // await launchUrl(uri);
            },
          ),

          const SizedBox(height: 10),

          _whiteTile(
            context,
            icon: Icons.location_on_rounded,
            title: 'Nearest Location',
            subtitle: '321 Rescue Road, Emergency Hub',
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // open maps later
              },
              child: const Text('Get Directions'),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Available Services',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...service.availableServices.map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8FFF0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF00C853)),
                  const SizedBox(width: 8),
                  Text(s),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.favorite, color: Color(0xFFFFA000)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Emergency responders are trained professionals ready to help you. '
                    'Stay calm, breathe slowly, and help will arrive soon.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _whiteTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade100,
                child: Icon(icon, color: Colors.grey.shade800),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }
}
