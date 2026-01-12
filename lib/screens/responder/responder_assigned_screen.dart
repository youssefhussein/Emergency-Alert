import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../providers/local_db_provider.dart';
import '../../services/responder_service.dart';
import 'responder_emergency_detail_screen.dart';
import 'responder_session_provider.dart';
import 'widgets/dispatch_actions_sheet.dart';
import 'widgets/emergency_sort_menu.dart';

final _refreshTickProvider = StateProvider<int>((ref) => 0);

class ResponderAssignedScreen extends ConsumerStatefulWidget {
  const ResponderAssignedScreen({super.key});

  @override
  ConsumerState<ResponderAssignedScreen> createState() => _ResponderAssignedScreenState();
}

class _ResponderAssignedScreenState extends ConsumerState<ResponderAssignedScreen> {
  EmergencySort _sort = EmergencySort.newest;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Light periodic refresh so countdown + statuses feel "alive" in demos.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) ref.read(_refreshTickProvider.notifier).state++;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final auth = ref.read(responderAuthProvider);
    final responder = auth.responder;
    if (responder == null) return [];
    final list = await ref.read(responderServiceProvider).getAssignedEmergencies(responderId: responder.id);
    // Sync to SQFlite cache for persistence + favorites.
    await ref.read(localDbProvider).upsertManyFromRemote(list);
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final responder = ref.watch(responderAuthProvider).responder;
    ref.watch(_refreshTickProvider); // triggers periodic rebuild

    if (responder == null) {
      return Scaffold(
        backgroundColor: c.surface,
        body: Center(
          child: Text('Sign in first.', style: TextStyle(color: c.onSurfaceVariant)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: const Text('Assigned Emergencies'),
        actions: [
          EmergencySortMenu(
            value: _sort,
            onChanged: (v) => setState(() => _sort = v),
          ),
          IconButton(
            tooltip: 'Dispatch controls',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                builder: (_) => DispatchActionsSheet(
                  onAfterAction: () {
                    Navigator.pop(context);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dispatch updated. Pull to refresh.')),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _load(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = (snap.data ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _EmptyState(responderId: responder.id),
                ],
              );
            }

            return FutureBuilder<Map<int, dynamic>>(
              future: () async {
                final ids = items.map((e) => (e['id'] as num).toInt()).toList();
                final meta = await ref.read(localDbProvider).getMetaForIds(ids);
                // return as dynamic map to keep FutureBuilder simple
                return meta;
              }(),
              builder: (context, metaSnap) {
                final meta = (metaSnap.data ?? <int, dynamic>{});

                // Apply local archive
                final filtered = items.where((e) {
                  final id = (e['id'] as num).toInt();
                  final m = meta[id];
                  final isArchived = m != null ? (m.isArchived as bool) : false;
                  return !isArchived;
                }).toList();

                // Sort
                filtered.sort((a, b) {
                  final idA = (a['id'] as num).toInt();
                  final idB = (b['id'] as num).toInt();
                  final favA = meta[idA] != null ? (meta[idA].isFavorite as bool) : false;
                  final favB = meta[idB] != null ? (meta[idB].isFavorite as bool) : false;

                  if (_sort == EmergencySort.favorites && favA != favB) {
                    return favB ? 1 : -1;
                  }

                  if (_sort == EmergencySort.status) {
                    return (a['status'] ?? '').toString().compareTo((b['status'] ?? '').toString());
                  }

                  final ca = DateTime.tryParse((a['created_at'] ?? '').toString());
                  final cb = DateTime.tryParse((b['created_at'] ?? '').toString());
                  final da = ca?.millisecondsSinceEpoch ?? 0;
                  final db = cb?.millisecondsSinceEpoch ?? 0;
                  return _sort == EmergencySort.oldest ? da.compareTo(db) : db.compareTo(da);
                });

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    final id = (e['id'] as num).toInt();
                    final isFav = meta[id] != null ? (meta[id].isFavorite as bool) : false;
                    return Dismissible(
                      key: ValueKey('emergency-$id'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: c.errorContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(Icons.archive, color: c.onErrorContainer),
                      ),
                      onDismissed: (_) async {
                        await ref.read(localDbProvider).setArchived(id, true);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Archived locally'),
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () async {
                                await ref.read(localDbProvider).setArchived(id, false);
                                if (mounted) setState(() {});
                              },
                            ),
                          ),
                        );
                        setState(() {});
                      },
                      child: _EmergencyCard(
                        emergency: e,
                        isFavorite: isFav,
                        onToggleFavorite: () async {
                          await ref.read(localDbProvider).toggleFavorite(id);
                          if (mounted) setState(() {});
                        },
                        onOpen: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResponderEmergencyDetailScreen(emergency: e),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final int responderId;
  const _EmptyState({required this.responderId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No assigned emergencies yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Use the Dispatch button (✨) to assign open emergencies to responders.\nResponder id: $responderId',
            style: theme.textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final Map<String, dynamic> emergency;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;

  const _EmergencyCard({
    required this.emergency,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final id = (emergency['id'] as num).toInt();
    final type = (emergency['type'] ?? 'unknown').toString();
    final status = (emergency['status'] ?? 'unknown').toString();
    final loc = (emergency['location_details'] ?? '').toString();
    final createdAt = DateTime.tryParse((emergency['created_at'] ?? '').toString());
    final createdText = createdAt == null ? '' : '${createdAt.toLocal()}';

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.outlineVariant.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#$id • ${type.toUpperCase()}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: onToggleFavorite,
                  icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                  tooltip: 'Favorite',
                ),
              ],
            ),
            Text(
              'Status: $status',
              style: theme.textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
            ),
            if (createdText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(createdText, style: theme.textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant)),
            ],
            if (loc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(loc, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}
