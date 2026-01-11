import 'dart:io' show Platform;

import 'package:contacts_service/contacts_service.dart' as device_contacts;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/contact.dart';
import '../../widgets/profile/contact_card_tile.dart';
import 'contacts_provider.dart';
import 'contacts_state.dart';
import 'view_contact_profile_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  @override
  void initState() {
    super.initState();
    // Load once when screen opens
    Future.microtask(() => ref.read(contactsProvider.notifier).load());
  }

  Future<void> _addFromContacts() async {
    final status = await Permission.contacts.request();

    if (status.isPermanentlyDenied) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Contacts Permission Required'),
          content: const Text(
            'Contacts permission is permanently denied. Please enable it in app settings to use this feature.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return;
    }

    if (!status.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contacts permission denied.')),
      );
      return;
    }

    if (!Platform.isAndroid && !Platform.isIOS) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact picker is only supported on Android and iOS.'),
        ),
      );
      return;
    }

    try {
      final picked =
          await device_contacts.ContactsService.openDeviceContactPicker();
      if (picked == null) return;

      final displayName = picked.displayName ?? '';
      String? phone;
      String? email;

      if (picked.phones != null && picked.phones!.isNotEmpty) {
        phone = picked.phones!.first.value;
      }
      if (picked.emails != null && picked.emails!.isNotEmpty) {
        email = picked.emails!.first.value;
      }

      final newContact = Contact(
        id: UniqueKey().toString(),
        ownerId: null,
        name: displayName.isNotEmpty
            ? displayName
            : (phone ?? email ?? 'Unknown'),
        status: 'active',
        phone: phone,
        email: email,
        relation: null,
        contactUserId: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        avatarUrl: null,
        notes: null,
        isPrimary: false,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Add Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${newContact.name}'),
              if (newContact.phone != null) Text('Phone: ${newContact.phone}'),
              if (newContact.email != null) Text('Email: ${newContact.email}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // TODO: replace with your actual save:
                // await ref.read(contactsProvider.notifier).addContact(newContact);

                Navigator.of(ctx).pop();

                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Contact added!')));
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick contact: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final state = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            tooltip: 'Search (UI only)',
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<ContactsSort>(
            tooltip: 'Sort',
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (v) => ref.read(contactsProvider.notifier).setSort(v),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: ContactsSort.favoritesFirst,
                child: Text('Favorites first'),
              ),
              PopupMenuItem(
                value: ContactsSort.nameAsc,
                child: Text('Name A → Z'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(contactsProvider.notifier).load();
        },
        child: state.loading
            ? const Center(child: CircularProgressIndicator())
            : state.error != null
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(state.error!)),
                ],
              )
            : state.items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text('No contacts yet.')),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final Contact c = state.items[index];
                  final bool isFav = state.favorites.contains(c.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: ValueKey(c.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.delete, color: cs.onErrorContainer),
                      ),
                      onDismissed: (_) async {
                        final removed = await ref
                            .read(contactsProvider.notifier)
                            .deleteContact(c.id);

                        if (!context.mounted || removed == null) return;

                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Deleted ${removed.name}'),
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () {
                                ref
                                    .read(contactsProvider.notifier)
                                    .undoDelete(removed, index: index);
                              },
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          ContactCardTile(
                            contact: c,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ViewContactProfileScreen(contact: c),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () {
                                  ref
                                      .read(contactsProvider.notifier)
                                      .toggleFavorite(c.id);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    isFav ? Icons.star : Icons.star_border,
                                    color: isFav ? cs.primary : cs.outline,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Contact',
        onPressed: _addFromContacts,
        child: const Icon(Icons.add),
      ),
    );
  }
}
