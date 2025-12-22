import 'package:flutter/material.dart';
import '../models/emergency.dart';

class EmergencyCard extends StatelessWidget {
  final Emergency emergency;
  final VoidCallback onTap;

  const EmergencyCard({
    super.key,
    required this.emergency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: emergency.bgColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(emergency.icon, color: emergency.color),
              ),
              const Spacer(),
              Text(
                emergency.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: emergency.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                emergency.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                emergency.primaryNumber,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
