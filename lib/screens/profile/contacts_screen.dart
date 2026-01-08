
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/contact.dart';
import 'view_contact_profile_screen.dart';
import '../../widgets/profile/contact_card_tile.dart';

import 'contacts_provider.dart';
import 'contacts_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final state = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: const Text('Emergency Contacts'),
        actions: [
          // keep your icons if you want the same look (search/filter)
          IconButton(
            tooltip: 'Search (UI only)',
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),

          // SORT (requirement)
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
        onRefresh: () => ref.read(contactsProvider.notifier).load(),
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
                          // Your existing tile (same design)
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

                          // FAVORITE button (requirement) - overlays without redesigning the tile
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
    );
  }
}
