import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/contact.dart';
import 'contacts_provider.dart';

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key});

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _relationCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _relationCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final contact = Contact(
      id: null,
      name: _nameCtrl.text.trim(),
      relation: _relationCtrl.text.trim().isEmpty
          ? null
          : _relationCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty
          ? null
          : _emailCtrl.text.trim().toLowerCase(),
      status: 'pending',
    );

    await ref.read(contactsProvider.notifier).addContact(contact);

    if (!mounted) return;
    setState(() => _saving = false);

    final err = ref.read(contactsProvider).error;
    if (err != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Failed: $err'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Contact added.'),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Emergency accent (red/SOS) that respects your global ColorScheme in light/dark.
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
          'Add Emergency Contact',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: cs.outlineVariant.withOpacity(0.7),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header “status” card like an emergency app
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.errorContainer.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.person_add_alt_1_rounded,
                        color: emergencyAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add someone you trust.\nThey’ll be shown in emergency sharing options.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              _field(
                cs: cs,
                controller: _nameCtrl,
                label: 'Full name',
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required.';
                  if (v.trim().length < 4 ||
                      v.trim().length > 50 ||
                      !RegExp(r"^[a-zA-Zà-žÀ-Ž'’\-\s]+$").hasMatch(v.trim()))
                    return 'Name has to be 4-50 letters long and contain only letters.';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              _field(
                cs: cs,
                controller: _relationCtrl,
                label: 'Relationship (optional)',
                icon: Icons.groups_2_outlined,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              _field(
                cs: cs,
                controller: _phoneCtrl,
                label: 'Phone number (optional)',
                textInputAction: TextInputAction.next,

                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Phone number is required.';
                  if (v.trim().length < 12 || v.trim().length > 15)
                    return 'Phone number is invalid.';
                  return null;
                },
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),

              _field(
                cs: cs,
                controller: _emailCtrl,
                label: 'Email (optional)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return null;
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s);
                  return ok ? null : 'Invalid email format.';
                },
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: emergencyAccent,
                    foregroundColor: onEmergencyAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _saving ? 'Saving...' : 'Save Contact',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.9)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'If the email belongs to a registered user, permissions will be created automatically.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required ColorScheme cs,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.error, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.error, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}
