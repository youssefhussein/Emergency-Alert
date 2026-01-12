import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/local_db_provider.dart';
import '../../services/responder_service.dart';
import 'responder_session_provider.dart';

class ResponderEmergencyDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> emergency;
  const ResponderEmergencyDetailScreen({super.key, required this.emergency});

  DateTime? _tryParseTime(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString()).toLocal();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    final id = (emergency['id'] as num).toInt();
    final type = (emergency['type'] ?? 'unknown').toString();
    final status = (emergency['status'] ?? 'unknown').toString();
    final notes = (emergency['notes'] ?? '').toString();
    final phone = (emergency['phone'] ?? '').toString();
    final locationDetails = (emergency['location_details'] ?? '').toString();
    final lat = emergency['location_lat'];
    final lng = emergency['location_lng'];
    final aiReport = (emergency['report_by_ai'] ?? '').toString();
    final createdAt = _tryParseTime(emergency['created_at']);
    final photoUrl = (emergency['photo_url'] ?? '').toString();
    final voiceUrl = (emergency['voice_note_url'] ?? '').toString();

    final responderId = ref.watch(responderAuthProvider).responder?.id;

    return Scaffold(
      backgroundColor: c.surface,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: Text('Emergency #$id'),
        actions: [
          IconButton(
            tooltip: 'Favorite',
            onPressed: () async {
              await ref.read(localDbProvider).toggleFavorite(id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Updated favorite')),
                );
              }
            },
            icon: const Icon(Icons.star_border),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _InfoCard(
            title: '${type.toUpperCase()} • $status',
            lines: [
              if (createdAt != null) 'Created: ${createdAt.toString()}',
              if (phone.isNotEmpty) 'Phone: $phone',
              if (locationDetails.isNotEmpty) 'Location details: $locationDetails',
              if (lat != null && lng != null) 'Coords: $lat, $lng',
            ],
          ),
          if (photoUrl.isNotEmpty || voiceUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MediaCard(photoUrl: photoUrl, voiceUrl: voiceUrl),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(title: 'Citizen notes', lines: [notes]),
          ],
          if (aiReport.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoCard(title: 'AI Report', lines: [aiReport]),
          ],
          const SizedBox(height: 16),
          _ActionStrip(
            emergencyId: id,
            status: status,
            responderId: responderId,
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: keep updates simple (Accepted → In Progress → Solved) for a clean demo.',
            style: theme.textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final String photoUrl;
  final String voiceUrl;
  const _MediaCard({required this.photoUrl, required this.voiceUrl});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.perm_media_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Media', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (photoUrl.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: InteractiveViewer(
                        child: Image.network(photoUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) {
                          return const Padding(
                            padding: EdgeInsets.all(18),
                            child: Text('Failed to load photo.'),
                          );
                        }),
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.image_outlined),
              label: const Text('View photo'),
            ),
          if (voiceUrl.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: voiceUrl));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Voice note link copied')),
                  );
                }
              },
              icon: const Icon(Icons.mic_none),
              label: const Text('Copy voice note link'),
            ),
        ],
      ),
    );
  }
}

class _ActionStrip extends ConsumerWidget {
  final int emergencyId;
  final String status;
  final int? responderId;

  const _ActionStrip({
    required this.emergencyId,
    required this.status,
    required this.responderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = Theme.of(context).colorScheme;
    final service = ref.read(responderServiceProvider);

    final canAccept = status == 'responder_assigned' && responderId != null;
    final canProgress = status == 'accepted' || status == 'in_progress';
    final canSolve = status == 'in_progress' || status == 'accepted';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canAccept)
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await service.acceptEmergency(emergencyId: emergencyId, responderId: responderId!);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Accept'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final reason = await _askRejectReason(context);
                    if (reason == null) return;
                    await service.rejectEmergency(emergencyId: emergencyId, responderId: responderId!, reason: reason);
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
              ),
            ],
          ),
        if (!canAccept)
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: canProgress
                      ? () async {
                          await service.setInProgress(emergencyId: emergencyId);
                          if (context.mounted) Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('In progress'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: c.tertiary),
                  onPressed: canSolve
                      ? () async {
                          await service.setSolved(emergencyId: emergencyId);
                          if (context.mounted) Navigator.pop(context);
                        }
                      : null,
                  icon: const Icon(Icons.task_alt),
                  label: const Text('Solved'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Future<String?> _askRejectReason(BuildContext context) async {
    final controller = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reject request'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Reason (required)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(ctx, text);
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return res;
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  const _InfoCard({required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.outlineVariant.withOpacity(0.5)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(l, style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
    );
  }
}
