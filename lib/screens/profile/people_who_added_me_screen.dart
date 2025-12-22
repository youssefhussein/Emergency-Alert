import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/contact.dart';
import '../../services/contacts_service.dart';
import 'package:emergency_alert/screens/profile/view_contact_profile_screen.dart';

class PeopleWhoAddedMeScreen extends StatefulWidget {
  const PeopleWhoAddedMeScreen({super.key});

  @override
  State<PeopleWhoAddedMeScreen> createState() => _PeopleWhoAddedMeScreenState();
}

class _PeopleWhoAddedMeScreenState extends State<PeopleWhoAddedMeScreen> {
  late final ContactsService _contactsService;
  bool _loading = true;
  String? _error;
  List<Contact> _items = [];

  @override
  void initState() {
    super.initState();
    _contactsService = ContactsService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _contactsService.getPeopleWhoAddedMe();
      if (!mounted) return;
      setState(() {
        _items = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load requests: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(Contact contact, bool accept) async {
    try {
      await _contactsService.respondToIncomingRequest(
        contactId: contact.id,
        accept: accept,
      );
      await _load(); // reload list after update
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update request: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('People Who Added Me')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              )
            : _items.isEmpty
            ? ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No one has added you as an emergency contact yet.',
                    ),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final contact = _items[index];
                  final isPending = contact.status == 'pending';

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (contact.name.isNotEmpty ? contact.name[0] : '?')
                            .toUpperCase(),
                      ),
                    ),
                    title: Text(contact.name),
                    subtitle: Text(
                      isPending
                          ? 'Sent you a request as emergency contact'
                          : 'Saved you as an emergency contact',
                    ),
                    trailing: isPending
                        ? Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                tooltip: 'Reject',
                                onPressed: () => _respond(contact, false),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                                tooltip: 'Accept',
                                onPressed: () => _respond(contact, true),
                              ),
                            ],
                          )
                        : const Icon(Icons.check_circle, color: Colors.green),
                    // TODO: onTap later: open their profile with permissions
                    onTap: () {
                      if (contact.ownerId != null &&
                          contact.status == 'accepted') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ViewContactProfileScreen(
                              contact: contact, // pass the whole Contact object
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}
