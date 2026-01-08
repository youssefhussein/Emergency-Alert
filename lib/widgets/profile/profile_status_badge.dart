import 'package:flutter/material.dart';

class ProfileStatusBadge extends StatelessWidget {
  final String status;
  final Map<String, String> labels;

  const ProfileStatusBadge({
    super.key,
    required this.status,
    required this.labels,
  });

  Color _statusColor(String? status, ThemeData theme) {
    switch (status) {
      case 'safe':
        return Colors.green;
      case 'need_help':
        return Colors.orange;
      case 'at_hospital':
        return Colors.blue;
      case 'in_danger':
        return Colors.red;
      case 'unavailable':
        return theme.colorScheme.outline;
      default:
        return theme.colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(status, theme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 10),
          const SizedBox(width: 6),
          Text(
            labels[status] ?? status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
