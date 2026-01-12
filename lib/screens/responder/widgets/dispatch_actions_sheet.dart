import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/dispatch_provider.dart';

class DispatchActionsSheet extends ConsumerWidget {
  final VoidCallback onAfterAction;
  const DispatchActionsSheet({super.key, required this.onAfterAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).colorScheme;
    final s = ref.watch(dispatchProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.memory_rounded),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI Dispatch Controls',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Assign open emergencies to the best available responders (type match + nearest).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: s.loading
                ? null
                : () async {
                    await ref.read(dispatchProvider.notifier).runDispatch(maxAssign: 200);
                    if (!context.mounted) return;
                    onAfterAction();
                  },
            icon: s.loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_fix_high),
            label: const Text('Run AI Dispatch (assign 200)'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: s.loading
                ? null
                : () async {
                    await ref.read(dispatchProvider.notifier).requeueExpired(expireSeconds: 60);
                    if (!context.mounted) return;
                    onAfterAction();
                  },
            icon: const Icon(Icons.timer_off_outlined),
            label: const Text('Requeue expired (60s)'),
          ),
          if (s.error != null) ...[
            const SizedBox(height: 10),
            Text(s.error!, style: TextStyle(color: c.error)),
          ],
          if (s.lastAssignedCount != null) ...[
            const SizedBox(height: 10),
            Text('Assigned: ${s.lastAssignedCount}', style: TextStyle(color: c.onSurfaceVariant)),
          ],
          if (s.lastRequeuedCount != null) ...[
            const SizedBox(height: 6),
            Text('Requeued: ${s.lastRequeuedCount}', style: TextStyle(color: c.onSurfaceVariant)),
          ],
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
