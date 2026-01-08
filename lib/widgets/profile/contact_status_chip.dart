import 'package:flutter/material.dart';

class ContactStatusChip extends StatelessWidget {
  final String status;

  const ContactStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    String text = status;
    Color color;
    Color bg;

    switch (status) {
      case 'active':
        color = const Color(0xFF2E7D32);
        bg = const Color(0xFFE8F5E9);
        text = 'Active';
        break;
      case 'pending':
        color = const Color(0xFF2962FF);
        bg = const Color(0xFFE3F2FD);
        text = 'Pending';
        break;
      default:
        color = Colors.grey.shade700;
        bg = Colors.grey.shade200;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
