import 'package:flutter/material.dart';
import '../../models/contact.dart';

class ContactProfileHeader extends StatelessWidget {
  final Contact contact;

  const ContactProfileHeader({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: cs.surface, // instead of Colors.white (supports dark mode)
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 40,
            backgroundColor: cs.primary.withOpacity(0.12),
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            contact.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            contact.relation ?? 'Emergency contact',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withOpacity(0.65),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
