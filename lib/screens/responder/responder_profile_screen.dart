import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'responder_session_provider.dart';

class ResponderProfileScreen extends ConsumerWidget {
  const ResponderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final responder = ref.watch(responderAuthProvider).responder;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: const Text('Responder Profile'),
      ),
      body: responder == null
          ? Center(child: Text('Not signed in.', style: TextStyle(color: c.onSurfaceVariant)))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: c.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: c.outlineVariant.withOpacity(0.5)),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: c.primary.withOpacity(0.12),
                          foregroundColor: c.primary,
                          child: const Icon(Icons.badge),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                responder.instituteName ?? 'Responder #${responder.id}',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Type: ${responder.type ?? 'Unknown'} • Status: ${responder.status ?? 'Unknown'}',
                                style: theme.textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
                              ),
                              if ((responder.addressName ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(responder.addressName!, style: theme.textTheme.bodyMedium),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Responder code (uuid):\n${responder.uuid}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(responderAuthProvider.notifier).logout();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(context, '/responder-login', (r) => false);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Demo note: for real responders, use Supabase Auth + RLS. For this project, UUID login is fine.',
                    style: theme.textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}
