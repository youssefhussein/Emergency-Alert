import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/user_profile.dart';
import '../../../services/profile_service.dart';
import 'edit_medical_info_screen.dart';

class MedicalInfoScreen extends StatefulWidget {
  const MedicalInfoScreen({super.key});

  @override
  State<MedicalInfoScreen> createState() => _MedicalInfoScreenState();
}

class _MedicalInfoScreenState extends State<MedicalInfoScreen> {
  late final ProfileService _profileService;
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _profile = await _profileService.getCurrentUserProfile();
    } catch (e) {
      _error = 'Failed to load medical info: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        title: const Text('Medical Information'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: TextStyle(color: cs.error)),
                    const SizedBox(height: 10),
                  ],

                  _infoBanner(context),
                  const SizedBox(height: 12),

                  _sectionTitle(context, 'Emergency-ready summary'),
                  const SizedBox(height: 8),
                  _card(
                    context,
                    children: [
                      _kv('Blood type', _profile?.bloodType),
                      _kv('Allergies', _profile?.allergies),
                      _kv('Chronic conditions', _profile?.chronicConditions),
                      _kv('Medications', _profile?.medications),
                      _kv('Disabilities', _profile?.disabilities),
                      _kv('Preferred hospital', _profile?.preferredHospital),
                    ],
                  ),

                  const SizedBox(height: 12),
                  _sectionTitle(context, 'Notes for responders'),
                  const SizedBox(height: 8),
                  _card(
                    context,
                    children: [
                      Text(
                        (_profile?.otherNotes == null ||
                                _profile!.otherNotes!.trim().isEmpty)
                            ? 'No notes provided.'
                            : _profile!.otherNotes!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditMedicalInfoScreen(),
                        ),
                      ).then((_) => _load());
                    },
                    child: const Text('Edit Medical Information'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoBanner(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This information helps responders treat you safely. '
              'Visibility depends on your Permissions & Settings.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withOpacity(0.8),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _kv(String k, String? v) {
    final value = (v == null || v.trim().isEmpty) ? '—' : v.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              k,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
