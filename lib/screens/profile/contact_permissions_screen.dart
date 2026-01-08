
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/contact_permissions_service.dart';
import '../../widgets/profile/permissions_switch_card.dart';

class ContactPermissionsScreen extends StatefulWidget {
  final String contactUserId;
  final String contactName;

  const ContactPermissionsScreen({
    super.key,
    required this.contactUserId,
    required this.contactName,
  });

  @override
  State<ContactPermissionsScreen> createState() =>
      _ContactPermissionsScreenState();
}

class _ContactPermissionsScreenState extends State<ContactPermissionsScreen> {
  late final ContactPermissionsService _permService;
  bool _loading = true;
  String? _error;

  bool shareStatus = true;
  bool shareMedical = true;
  bool shareLocation = true;

  @override
  void initState() {
    super.initState();
    _permService = ContactPermissionsService(Supabase.instance.client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final perms = await _permService.getPermissions(
        ownerId: user.id,
        contactUserId: widget.contactUserId,
      );

      if (perms != null) {
        shareStatus = perms.canViewStatus;
        shareMedical = perms.canViewMedical;
        shareLocation = perms.canViewLocation;
      }
    } catch (e) {
      _error = 'Failed to load permissions: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      await _permService.setPermissions(
        ownerId: user.id,
        contactUserId: widget.contactUserId,
        status: shareStatus,
        medical: shareMedical,
        location: shareLocation,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Permissions saved')));
      }
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Permissions for ${widget.contactName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Text(
                  'What can ${widget.contactName} see?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                PermissionsSwitchCard(
                  shareStatus: shareStatus,
                  shareMedical: shareMedical,
                  shareLocation: shareLocation,
                  onStatusChanged: (v) => setState(() => shareStatus = v),
                  onMedicalChanged: (v) => setState(() => shareMedical = v),
                  onLocationChanged: (v) => setState(() => shareLocation = v),
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
    );
  }
}
