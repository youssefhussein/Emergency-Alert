
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/contact.dart';
import '../../services/contacts_service.dart';
import 'view_contact_profile_screen.dart';

import '../../widgets/profile/incoming_request_tile.dart';

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
      setState(() => _items = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load requests: $e');
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
      await _load();
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

                  return IncomingRequestTile(
                    contact: contact,
                    isPending: isPending,
                    onReject: () => _respond(contact, false),
                    onAccept: () => _respond(contact, true),
                    onTapAccepted: () {
                      if (contact.ownerId != null &&
                          contact.status == 'accepted') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ViewContactProfileScreen(contact: contact),
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
