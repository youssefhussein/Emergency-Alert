import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/user_profile.dart';
import '../../../services/profile_service.dart';

class EditMedicalInfoScreen extends StatefulWidget {
  const EditMedicalInfoScreen({super.key});

  @override
  State<EditMedicalInfoScreen> createState() => _EditMedicalInfoScreenState();
}

class _EditMedicalInfoScreenState extends State<EditMedicalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bloodTypeCtrl = TextEditingController();
  final _chronicCtrl = TextEditingController();
  final _medicationsCtrl = TextEditingController();
  final _disabilitiesCtrl = TextEditingController();
  final _preferredHospitalCtrl = TextEditingController();
  final _otherNotesCtrl = TextEditingController();

  final _allergyInputCtrl = TextEditingController();
  List<String> _allergies = [];

  late final ProfileService _profileService;
  UserProfile? _current;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(Supabase.instance.client);
    _load();
  }

  @override
  void dispose() {
    _bloodTypeCtrl.dispose();
    _chronicCtrl.dispose();
    _medicationsCtrl.dispose();
    _disabilitiesCtrl.dispose();
    _preferredHospitalCtrl.dispose();
    _otherNotesCtrl.dispose();
    _allergyInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _current = await _profileService.getCurrentUserProfile();

      _bloodTypeCtrl.text = _current?.bloodType ?? '';
      _chronicCtrl.text = _current?.chronicConditions ?? '';
      _medicationsCtrl.text = _current?.medications ?? '';
      _disabilitiesCtrl.text = _current?.disabilities ?? '';
      _preferredHospitalCtrl.text = _current?.preferredHospital ?? '';
      _otherNotesCtrl.text = _current?.otherNotes ?? '';

      final allergiesString = _current?.allergies;
      if (allergiesString != null && allergiesString.trim().isNotEmpty) {
        _allergies = allergiesString
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        _allergies = [];
      }
    } catch (e) {
      _error = 'Failed to load: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _addAllergy() {
    final text = _allergyInputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _allergies.add(text);
      _allergyInputCtrl.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _error = 'Not signed in');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // Preserve basic profile fields; only update medical fields here.
      final base = _current;
      final updated = UserProfile(
        id: user.id,
        fullName: base?.fullName,
        phone: base?.phone,
        profileImageUrl: base?.profileImageUrl,
        profileStatus: base?.profileStatus,
        age: base?.age,
        gender: base?.gender,
        weightKg: base?.weightKg,
        heightCm: base?.heightCm,
        bloodType: _bloodTypeCtrl.text.trim().isEmpty
            ? null
            : _bloodTypeCtrl.text.trim(),
        allergies: _allergies.isEmpty ? null : _allergies.join(', '),
        chronicConditions:
            _chronicCtrl.text.trim().isEmpty ? null : _chronicCtrl.text.trim(),
        medications: _medicationsCtrl.text.trim().isEmpty
            ? null
            : _medicationsCtrl.text.trim(),
        disabilities: _disabilitiesCtrl.text.trim().isEmpty
            ? null
            : _disabilitiesCtrl.text.trim(),
        preferredHospital: _preferredHospitalCtrl.text.trim().isEmpty
            ? null
            : _preferredHospitalCtrl.text.trim(),
        otherNotes: _otherNotesCtrl.text.trim().isEmpty
            ? null
            : _otherNotesCtrl.text.trim(),
      );

      await _profileService.upsertCurrentUserProfile(updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medical information saved.')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _maxLen(String? v, int max, String label) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length > max) return '$label must be at most $max characters';
    return null;
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
        title: const Text('Edit Medical Information'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) ...[
                    Text(_error!, style: TextStyle(color: cs.error)),
                    const SizedBox(height: 10),
                  ],

                  _sectionTitle(context, 'Core'),
                  const SizedBox(height: 8),
                  _card(
                    context,
                    children: [
                      TextFormField(
                        controller: _bloodTypeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Blood type',
                          hintText: 'e.g., O+, A-',
                        ),
                        validator: (v) => _maxLen(v, 10, 'Blood type'),
                      ),
                      const SizedBox(height: 12),
                      _allergiesEditor(context),
                    ],
                  ),

                  const SizedBox(height: 14),
                  _sectionTitle(context, 'Health conditions'),
                  const SizedBox(height: 8),
                  _card(
                    context,
                    children: [
                      TextFormField(
                        controller: _chronicCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Chronic conditions',
                          hintText: 'e.g., asthma, diabetes',
                        ),
                        maxLines: 2,
                        validator: (v) => _maxLen(v, 200, 'Chronic conditions'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _medicationsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Medications',
                          hintText: 'e.g., insulin, inhaler',
                        ),
                        maxLines: 2,
                        validator: (v) => _maxLen(v, 200, 'Medications'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _disabilitiesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Disabilities',
                          hintText: 'Optional',
                        ),
                        maxLines: 2,
                        validator: (v) => _maxLen(v, 200, 'Disabilities'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  _sectionTitle(context, 'Responder notes'),
                  const SizedBox(height: 8),
                  _card(
                    context,
                    children: [
                      TextFormField(
                        controller: _preferredHospitalCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Preferred hospital',
                          hintText: 'Optional',
                        ),
                        validator: (v) => _maxLen(v, 120, 'Preferred hospital'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _otherNotesCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Other notes',
                          hintText: 'Anything responders should know',
                        ),
                        maxLines: 3,
                        validator: (v) => _maxLen(v, 300, 'Other notes'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _allergiesEditor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Allergies',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _allergyInputCtrl,
                decoration: const InputDecoration(
                  hintText: 'Add allergy (e.g., penicillin)',
                ),
                onFieldSubmitted: (_) => _addAllergy(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: _addAllergy,
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_allergies.isEmpty)
          Text(
            'No allergies added.',
            style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergies
                .map(
                  (a) => Chip(
                    label: Text(a),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() => _allergies.remove(a));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Removed allergy: $a')),
                      );
                    },
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
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
}
