import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/emergency_service.dart';

class EmergencyFollowUpScreen extends StatefulWidget {
  final int emergencyId;
  final EmergencyService service;

  const EmergencyFollowUpScreen({
    super.key,
    required this.emergencyId,
    required this.service,
  });

  @override
  State<EmergencyFollowUpScreen> createState() =>
      _EmergencyFollowUpScreenState();
}

class _EmergencyFollowUpScreenState extends State<EmergencyFollowUpScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, dynamic>? _row;
  bool _loading = true;
  String? _error;

  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  @override
  void initState() {
    super.initState();
    _loadOnce();
    _listenRealtime();
  }

  Future<void> _loadOnce() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _supabase
          .from('emergencies')
          .select('*')
          .eq('id', widget.emergencyId)
          .single();

      if (!mounted) return;
      setState(() {
        _row = Map<String, dynamic>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "$e";
        _loading = false;
      });
    }
  }

  void _listenRealtime() {
    _sub = _supabase
        .from('emergencies')
        .stream(primaryKey: ['id'])
        .eq('id', widget.emergencyId)
        .listen(
          (rows) {
            if (!mounted) return;
            if (rows.isEmpty) return;

            setState(() {
              _row = rows.first;
              if (_loading) _loading = false;
              _error = null;
            });
          },
          onError: (e) {
            if (!mounted) return;
            setState(() => _error = "$e");
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ===== UI helpers =====

  String _statusLabel(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'open':
        return 'Request received';
      case 'dispatched':
        return 'Dispatching responders';
      case 'responder_assigned':
        return 'Responder assigned';
      case 'in_progress':
        return 'Responder en route';
      case 'resolved':
        return 'Resolved';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status?.isNotEmpty == true ? status! : 'Unknown';
    }
  }

  IconData _statusIcon(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'open':
        return Icons.mark_email_read_outlined;
      case 'dispatched':
        return Icons.bolt_outlined;
      case 'responder_assigned':
        return Icons.person_pin_circle_outlined;
      case 'in_progress':
        return Icons.directions_run_outlined;
      case 'resolved':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Color _statusColor(ColorScheme c, String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
      case 'responder_assigned':
      case 'dispatched':
        return c.primary;
      case 'open':
      default:
        return c.onSurfaceVariant;
    }
  }

  int _stepIndex(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'open':
        return 0;
      case 'dispatched':
        return 1;
      case 'responder_assigned':
        return 2;
      case 'in_progress':
        return 3;
      case 'resolved':
        return 4;
      default:
        return 0;
    }
  }

  // ===== THEME MATCH: same feel as EmergencyAdditionalInfoScreen =====
  // - Scaffold background uses theme.scaffoldBackgroundColor
  // - Content wrapped in ONE main card with shadow
  // - AppBar uses surface colors and back arrow only if canPop
  // - Uses same spacing + rounded corners + outlineVariant borders

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final shadowColor = isDark ? Colors.black54 : Colors.black12;

    final status = _row?['status'] as String?;
    final createdAt = _row?['created_at']?.toString();
    final shareLocation = _row?['share_location'] as bool?;
    final notifyContacts = _row?['notify_contacts'] as bool?;
    final locationDetails = _row?['location_details'] as String?;
    final photoUrl = _row?['photo_url'] as String?;
    final voiceUrl = _row?['voice_note_url'] as String?;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Emergency Follow-Up'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _errorState(context)
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header row (icon + title) like the other screen
                          Row(
                            children: [
                              Icon(
                                Icons.track_changes_outlined,
                                color: isDark
                                    ? Colors.red[300]
                                    : Colors.redAccent,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Live Status',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Spacer(),
                              // small pill with case id
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: (isDark
                                      ? Colors.grey[900]
                                      : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: c.outlineVariant),
                                ),
                                child: Text(
                                  'Case #${widget.emergencyId}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: c.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          _headerCard(
                            context,
                            status: status,
                            createdAt: createdAt,
                          ),
                          const SizedBox(height: 12),

                          _timelineCard(context, status: status),
                          const SizedBox(height: 12),

                          _detailsCard(
                            context,
                            shareLocation: shareLocation ?? false,
                            notifyContacts: notifyContacts ?? false,
                            locationDetails: locationDetails,
                          ),
                          const SizedBox(height: 12),

                          _mediaCard(
                            context,
                            photoUrl: photoUrl,
                            voiceUrl: voiceUrl,
                          ),
                          const SizedBox(height: 14),

                          _actionsRow(context),

                          const SizedBox(height: 20),
                          _safetyHint(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _errorState(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black54 : Colors.black12,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 10),
              Text(
                'Could not load this emergency.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadOnce, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard(
    BuildContext context, {
    required String? status,
    required String? createdAt,
  }) {
    final c = Theme.of(context).colorScheme;
    final statusText = _statusLabel(status);
    final icon = _statusIcon(status);
    final color = _statusColor(c, status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'Case #${widget.emergencyId} • ${widget.service.name}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
                ),
                if (createdAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Created: $createdAt',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineCard(BuildContext context, {required String? status}) {
    final c = Theme.of(context).colorScheme;
    final idx = _stepIndex(status);

    final steps = const [
      'Request received',
      'Dispatch started',
      'Responder assigned',
      'Responder en route',
      'Resolved',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < steps.length; i++)
            _stepRow(
              context,
              title: steps[i],
              done: i <= idx,
              active: i == idx,
            ),
        ],
      ),
    );
  }

  Widget _stepRow(
    BuildContext context, {
    required String title,
    required bool done,
    required bool active,
  }) {
    final c = Theme.of(context).colorScheme;
    final dotColor = done ? c.primary : c.outlineVariant;
    final textColor = active ? c.onSurface : c.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: dotColor.withOpacity(done ? 0.22 : 0.12),
              border: Border.all(color: dotColor),
              shape: BoxShape.circle,
            ),
            child: done ? Icon(Icons.check, size: 12, color: dotColor) : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard(
    BuildContext context, {
    required bool shareLocation,
    required bool notifyContacts,
    required String? locationDetails,
  }) {
    final c = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _infoLine(
            Icons.location_on_outlined,
            'Share Location',
            shareLocation ? 'Yes' : 'No',
          ),
          _infoLine(
            Icons.group_outlined,
            'Notify Contacts',
            notifyContacts ? 'Yes' : 'No',
          ),
          if (locationDetails != null && locationDetails.trim().isNotEmpty)
            _infoLine(
              Icons.apartment_outlined,
              'Location Details',
              locationDetails.trim(),
            ),
        ],
      ),
    );
  }

  Widget _mediaCard(
    BuildContext context, {
    required String? photoUrl,
    required String? voiceUrl,
  }) {
    final c = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _infoLine(Icons.photo_outlined, 'Photo', photoUrl ?? 'Not attached'),
          _infoLine(
            Icons.mic_none_outlined,
            'Voice Note',
            voiceUrl ?? 'Not attached',
          ),
          const SizedBox(height: 10),
          Text(
            'Tip: store paths in DB (not signed URLs). Generate signed URLs only when displaying media.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _actionsRow(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call'),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.onSurface,
              side: BorderSide(color: c.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Open live updates (hook later)')),
              );
            },
            icon: const Icon(Icons.track_changes_outlined),
            label: const Text('Updates'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _safetyHint(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.primaryContainer.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: c.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Stay on this screen. If you are in immediate danger, call emergency services directly.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String title, String value) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: c.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 130,
            child: Text(title, style: TextStyle(color: c.onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: c.onSurface)),
          ),
        ],
      ),
    );
  }
}
