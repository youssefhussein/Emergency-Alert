import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:emergency_alert/widgets/empty_state.dart';
import 'emergency_history_provider.dart';
import 'emergency_history_state.dart';

class EmergencyHistoryScreen extends ConsumerStatefulWidget {
  const EmergencyHistoryScreen({super.key});

  @override
  ConsumerState<EmergencyHistoryScreen> createState() =>
      _EmergencyHistoryScreenState();
}

class _EmergencyHistoryScreenState
    extends ConsumerState<EmergencyHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final state = ref.watch(emergencyHistoryProvider);
    final notifier = ref.read(emergencyHistoryProvider.notifier);

    final items = notifier.visibleItems;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: const Text('Emergency History'),
        actions: [
          PopupMenuButton<HistorySort>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded),
            onSelected: notifier.setSort,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: HistorySort.newestFirst,
                child: Text('Newest first'),
              ),
              PopupMenuItem(
                value: HistorySort.oldestFirst,
                child: Text('Oldest first'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => notifier.load(),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _filterChips(context, state.filter, notifier.setFilter),
            ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(state.error!, style: TextStyle(color: cs.error)),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => notifier.load(),
                child: state.loading
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          EmptyState(
                            title: 'No history yet',
                            message:
                                'Your emergency requests will appear here for review and accountability.',
                            icon: Icons.history,
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final e = items[i];
                          final statusUi = _statusChip(theme, e.status);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: ValueKey('history_${e.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.errorContainer,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  Icons.delete,
                                  color: cs.onErrorContainer,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Delete record?'),
                                        content: const Text(
                                          'This removes the emergency record from your history. Use only if it was created by mistake.',
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
                                final removed = await notifier.delete(e.id);
                                if (!context.mounted || removed == null) return;

                                ScaffoldMessenger.of(context).clearSnackBars();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Record deleted'),
                                    action: SnackBarAction(
                                      label: 'UNDO',
                                      onPressed: () =>
                                          notifier.undoDelete(removed),
                                    ),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 0,
                                color: cs.surfaceContainerHighest,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: cs.primary.withOpacity(
                                      0.12,
                                    ),
                                    child: Icon(
                                      _typeIcon(e.type),
                                      color: cs.primary,
                                    ),
                                  ),
                                  title: Text(
                                    _typeLabel(e.type),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      _formatWhen(e.createdAt),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  trailing: statusUi,
                                  onTap: () {
                                    // Read-only details dialog (keeps depth ≤ 2)
                                    showModalBottomSheet(
                                      context: context,
                                      showDragHandle: true,
                                      builder: (_) => _HistoryDetailsSheet(
                                        type: e.type,
                                        status: e.status,
                                        createdAt: e.createdAt,
                                        notes: e.notes,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChips(
    BuildContext context,
    HistoryFilter current,
    void Function(HistoryFilter) onChanged,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _chip(
            context,
            label: 'All',
            selected: current == HistoryFilter.all,
            onTap: () => onChanged(HistoryFilter.all),
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            label: 'Open',
            selected: current == HistoryFilter.open,
            onTap: () => onChanged(HistoryFilter.open),
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            label: 'Assigned',
            selected: current == HistoryFilter.assigned,
            onTap: () => onChanged(HistoryFilter.assigned),
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            label: 'Responding',
            selected: current == HistoryFilter.responding,
            onTap: () => onChanged(HistoryFilter.responding),
          ),
          const SizedBox(width: 8),
          _chip(
            context,
            label: 'Resolved',
            selected: current == HistoryFilter.resolved,
            onTap: () => onChanged(HistoryFilter.resolved),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? cs.primary : cs.outlineVariant),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? cs.onPrimary : cs.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _statusChip(ThemeData theme, String status) {
    final cs = theme.colorScheme;

    final normalized = status.toLowerCase().trim();
    late final String label;
    late final Color bg;
    late final Color fg;

    switch (normalized) {
      case 'resolved':
      case 'closed':
        label = 'Resolved';
        bg = Colors.green.withOpacity(0.15);
        fg = Colors.green.shade800;
        break;
      case 'responding':
        label = 'Responding';
        bg = cs.tertiary.withOpacity(0.15);
        fg = cs.tertiary;
        break;
      case 'assigned':
        label = 'Assigned';
        bg = cs.secondary.withOpacity(0.15);
        fg = cs.secondary;
        break;
      case 'open':
      case 'pending':
      default:
        label = 'Open';
        bg = cs.primary.withOpacity(0.15);
        fg = cs.primary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'police':
        return Icons.shield_outlined;
      case 'fire':
        return Icons.local_fire_department_outlined;
      case 'hospital':
        return Icons.local_hospital_outlined;
      case 'ambulance':
      default:
        return Icons.emergency_outlined;
    }
  }

  String _typeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'police':
        return 'Police';
      case 'fire':
        return 'Fire';
      case 'hospital':
        return 'Hospital';
      case 'ambulance':
        return 'Ambulance';
      default:
        return type;
    }
  }

  String _formatWhen(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _HistoryDetailsSheet extends StatelessWidget {
  final String type;
  final String status;
  final DateTime createdAt;
  final String? notes;

  const _HistoryDetailsSheet({
    required this.type,
    required this.status,
    required this.createdAt,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Request details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _kv(context, 'Type', type),
            _kv(context, 'Status', status),
            _kv(context, 'Created', createdAt.toLocal().toString()),
            const SizedBox(height: 10),
            Text(
              'Notes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                (notes == null || notes!.trim().isEmpty)
                    ? 'No notes provided.'
                    : notes!,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              k,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text(v, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
