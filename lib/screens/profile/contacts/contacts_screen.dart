import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/contact.dart';
import '../../../widgets/profile/contact_card_tile.dart';
import 'add_contact_screen.dart';
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
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.read(contactsProvider.notifier).load(),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.read(contactsProvider.notifier).load(),
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
                  final int? id = c.id;
                  final bool isFav = id != null && state.favorites.contains(id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: ValueKey('contact_${id ?? index}'),
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
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete contact?'),
                                content: Text(
                                  'Delete ${c.name} from your emergency contacts?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton.tonal(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (_) async {
                        if (id == null) return;
                        final removed = await ref
                            .read(contactsProvider.notifier)
                            .deleteContact(id);
                        if (!context.mounted || removed == null) return;

                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Deleted ${removed.name}'),
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () => ref
                                  .read(contactsProvider.notifier)
                                  .undoDelete(removed),
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
                                onTap: id == null
                                    ? null
                                    : () => ref
                                          .read(contactsProvider.notifier)
                                          .toggleFavorite(id),
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddContactScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
