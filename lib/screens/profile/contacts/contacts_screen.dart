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
  // Small helper to keep empty/error UI consistent with your app style.
  Widget _statusState({
    required ColorScheme cs,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 72),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.outlineVariant),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.errorContainer.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, size: 34, color: cs.error),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (onAction != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionText ?? 'Try again'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(contactsProvider);

    // “Emergency app” accent: prefer error/red for key actions in this screen.
    // Uses cs.error so it respects light/dark + your global theme setup.
    final emergencyAccent = cs.error;
    final onEmergencyAccent = cs.onError;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleSpacing: 12,
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: cs.outlineVariant.withOpacity(0.7),
          ),
        ),
        actions: [
          PopupMenuButton<ContactsSort>(
            tooltip: 'Sort',
            icon: const Icon(Icons.tune_rounded),
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
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: emergencyAccent,
        onRefresh: () async => ref.read(contactsProvider.notifier).load(),
        child: state.loading
            ? Center(child: CircularProgressIndicator(color: emergencyAccent))
            : state.error != null
            ? _statusState(
                cs: cs,
                icon: Icons.wifi_off_rounded,
                title: 'Couldn’t load contacts',
                subtitle: state.error!,
                onAction: () => ref.read(contactsProvider.notifier).load(),
                actionText: 'Retry',
              )
            : state.items.isEmpty
            ? _statusState(
                cs: cs,
                icon: Icons.health_and_safety_rounded,
                title: 'No emergency contacts yet',
                subtitle:
                    'Add trusted people so you can quickly share critical info in an emergency.',
                onAction: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddContactScreen()),
                  );
                },
                actionText: 'Add contact',
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              cs.surfaceContainerHighest,
                              cs.errorContainer,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.delete_rounded,
                              color: cs.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: cs.onErrorContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                icon: Icon(
                                  Icons.delete_rounded,
                                  color: cs.error,
                                ),
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
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: cs.error,
                                      foregroundColor: cs.onError,
                                    ),
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
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: cs.surfaceContainerHighest,
                            content: Text(
                              'Deleted ${removed.name}',
                              style: TextStyle(color: cs.onSurface),
                            ),
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
                          // Your existing tile. Theme consistency comes from the
                          // global ThemeData + the screen styling above.
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

                          // Favorite button: show “emergency accent” when active.
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: id == null
                                    ? null
                                    : () => ref
                                          .read(contactsProvider.notifier)
                                          .toggleFavorite(id),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest
                                        .withOpacity(0.75),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: cs.outlineVariant.withOpacity(0.8),
                                    ),
                                  ),
                                  child: Icon(
                                    isFav
                                        ? Icons.star_rounded
                                        : Icons.star_border_rounded,
                                    color: isFav ? emergencyAccent : cs.outline,
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: emergencyAccent,
        foregroundColor: onEmergencyAccent,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddContactScreen()),
          );
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Add Contact',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
