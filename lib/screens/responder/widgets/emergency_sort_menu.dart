import 'package:flutter/material.dart';

enum EmergencySort { newest, oldest, status, favorites }

class EmergencySortMenu extends StatelessWidget {
  final EmergencySort value;
  final ValueChanged<EmergencySort> onChanged;
  const EmergencySortMenu({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<EmergencySort>(
      icon: const Icon(Icons.sort),
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: EmergencySort.newest, child: Text('Newest')),
        PopupMenuItem(value: EmergencySort.oldest, child: Text('Oldest')),
        PopupMenuItem(value: EmergencySort.status, child: Text('By status')),
        PopupMenuItem(value: EmergencySort.favorites, child: Text('Favorites first')),
      ],
    );
  }
}
