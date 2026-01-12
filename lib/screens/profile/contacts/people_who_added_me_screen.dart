import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/contact.dart';
import '../../../services/contacts_service.dart';
import '../../../services/contact_permissions_service.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/profile/incoming_request_tile.dart';
import 'contact_permissions_screen.dart';
import 'view_contact_profile_screen.dart';

/// "People Who Added Me" (viewer-side requests).
///
/// Rows come from `contacts` where `contact_user_id == currentUser.id`.
/// - Accept/Reject updates the *request owner's* contact row `status`.
/// - On Accept, we also create default permissions in `contact_permissions` so
///   the requester (viewer) can see a minimal safe subset of *your* profile.
class PeopleWhoAddedMeScreen extends StatefulWidget {
  const PeopleWhoAddedMeScreen({super.key});

  @override
  State<PeopleWhoAddedMeScreen> createState() => _PeopleWhoAddedMeScreenState();
}

class _PeopleWhoAddedMeScreenState extends State<PeopleWhoAddedMeScreen> {
  late final ContactsService _contactsService;
  late final ContactPermissionsService _permissionsService;

  bool _loading = true;
  String? _error;
  List<Contact> _items = [];

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _contactsService = ContactsService(client);
    _permissionsService = ContactPermissionsService(client);
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
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    try {
      await _contactsService.respondToIncomingRequest(
        contactId: contact.id!,
        accept: accept,
      );

      // If accepted, create default permissions so the requester (contact.ownerId)
      // can view a safe subset of *my* profile.
      if (accept && currentUserId != null && contact.ownerId != null) {
        await _permissionsService.upsertPermissions(
          ownerId: currentUserId,
          viewerId: contact.ownerId!,
          canViewBasicProfile: true,
          canViewStatus: true,
          canViewLocation: false,
          canViewMedical: false,
          canViewEmergencyInfo: false,
        );
      }

      await _load();

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Request accepted.' : 'Request rejected.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update request: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: const Text('People Who Added Me'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [Text(_error!, style: TextStyle(color: cs.error))],
              )
            : _items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  EmptyState(
                    icon: Icons.person_add_alt_1_outlined,
                    title: 'No requests',
                    message:
                        'When someone adds you as an emergency contact, their request will appear here.',
                  ),
                ],
              )
            : ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final contact = _items[index];
                  final isPending = contact.status == 'pending';
                  final isAccepted = contact.status == 'accepted';

                  return Column(
                    children: [
                      IncomingRequestTile(
                        contact: contact,
                        isPending: isPending,
                        onReject: () => _respond(contact, false),
                        onAccept: () => _respond(contact, true),
                        onTapAccepted: () {
                          // Viewer can open the requester's profile only if the requester
                          // is linked to an app user (ownerId exists).
                          if (contact.ownerId != null && isAccepted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ViewContactProfileScreen(
                                  contact: Contact(
                                    id: contact.id,
                                    ownerId: contact.ownerId,
                                    contactUserId: contact
                                        .ownerId, // treat requester as the profile owner
                                    name: contact.contactNameForDisplay,
                                    phone: contact.phone,
                                    email: contact.email,
                                    relation: contact.relation,
                                    status: contact.status,
                                    createdAt: contact.createdAt,
                                    updatedAt: contact.updatedAt,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                      ),

                      if (isAccepted && contact.ownerId != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.lock_outline),
                              label: const Text(
                                'Manage what they can see about me',
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ContactPermissionsScreen(
                                      contactUserId: contact.ownerId!,
                                      contactName: contact.name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

extension _ContactDisplayName on Contact {
  String get contactNameForDisplay {
    // In "people who added me" list, contact_name is typically my name as saved by them.
    // If it's empty, fall back to email/phone.
    if (name.trim().isNotEmpty) return name.trim();
    if ((email ?? '').trim().isNotEmpty) return email!.trim();
    if ((phone ?? '').trim().isNotEmpty) return phone!.trim();
    return 'User';
  }
}
