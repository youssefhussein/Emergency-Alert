import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/contact_permissions_service.dart';
import '../../../widgets/profile/permissions_switch_card.dart';

class ContactPermissionsScreen extends StatefulWidget {
  /// The contact user's uuid (auth.users.id).
  /// (Kept as `contactUserId` to match your existing navigation calls.)
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
  bool shareMedical = false;
  bool shareLocation = false;

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
        viewerId: widget.contactUserId,
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

      await _permService.upsertPermissions(
        ownerId: user.id,
        viewerId: widget.contactUserId,
        canViewStatus: shareStatus,
        canViewMedical: shareMedical,
        canViewLocation: shareLocation,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Permissions saved'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Failed to save: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Emergency accent (SOS red) consistent with the other screens.
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
        title: Text(
          'Permissions for ${widget.contactName}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: cs.outlineVariant.withOpacity(0.7),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: emergencyAccent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
              children: [
                // Header / context card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.errorContainer.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.privacy_tip_outlined,
                          color: emergencyAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Privacy controls',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Choose what ${widget.contactName} can access in emergencies.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cs.error.withOpacity(0.6)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline_rounded, color: cs.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _error!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onErrorContainer,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                Text(
                  'What can ${widget.contactName} see?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tip: Enable only what’s necessary. You can change this anytime.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 14),

                // Your existing widget (kept intact)
                PermissionsSwitchCard(
                  shareStatus: shareStatus,
                  shareMedical: shareMedical,
                  shareLocation: shareLocation,
                  onStatusChanged: (v) => setState(() => shareStatus = v),
                  onMedicalChanged: (v) => setState(() => shareMedical = v),
                  onLocationChanged: (v) => setState(() => shareLocation = v),
                ),

                const SizedBox(height: 18),

                // “Emergency app” CTA
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: emergencyAccent,
                      foregroundColor: onEmergencyAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.save_rounded),
                    label: const Text(
                      'Save Permissions',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.9),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'These settings affect what this contact can view from your profile during emergency workflows.',
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
    );
  }
}
