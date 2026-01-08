import 'package:flutter/material.dart';

class PermissionsSwitchCard extends StatelessWidget {
  final bool shareStatus;
  final bool shareMedical;
  final bool shareLocation;
  final ValueChanged<bool> onStatusChanged;
  final ValueChanged<bool> onMedicalChanged;
  final ValueChanged<bool> onLocationChanged;

  const PermissionsSwitchCard({
    super.key,
    required this.shareStatus,
    required this.shareMedical,
    required this.shareLocation,
    required this.onStatusChanged,
    required this.onMedicalChanged,
    required this.onLocationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Live status'),
            subtitle: const Text('Safe, need help, at hospital, in danger'),
            value: shareStatus,
            onChanged: onStatusChanged,
          ),
          const Divider(height: 0),
          SwitchListTile(
            title: const Text('Medical & emergency info'),
            subtitle: const Text('Blood type, allergies, medications'),
            value: shareMedical,
            onChanged: onMedicalChanged,
          ),
          const Divider(height: 0),
          SwitchListTile(
            title: const Text('Approximate location'),
            subtitle: const Text('Only when you send an emergency alert'),
            value: shareLocation,
            onChanged: onLocationChanged,
          ),
        ],
      ),
    );
  }
}
