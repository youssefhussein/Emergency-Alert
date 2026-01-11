import 'package:flutter/material.dart';
// gives access to themeController

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // later: load from Supabase
    final contacts = [
      ('Sarah Johnson', 'Mother', '+1 (555) 123-4567'),
      ('Michael Chen', 'Brother', '+1 (555) 234-5678'),
      ('Dr. Emily Parker', 'Family Doctor', '+1 (555) 345-6789'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFE8F2FF),
            child: const Text(
              'These contacts will be notified when you use emergency services. '
              'Add people you trust.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final c = contacts[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(c.$1),
                    subtitle: Text('${c.$2}\n${c.$3}'),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 12),
                        Icon(Icons.delete_outline, size: 18),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ElevatedButton.icon(
              onPressed: () {
                // open add contact form
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Contact'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
              ),
              onPressed: () {
                // notify all contacts
              },
              icon: const Icon(Icons.campaign_rounded),
              label: const Text('Alert All Contacts'),
            ),
          ),
        ],
      ),
    );
  }
}
