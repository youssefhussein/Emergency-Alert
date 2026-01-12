import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/contact.dart' as app_models;
import '../../../models/user_profile.dart';
import '../../../services/profile_service.dart';
import '../../../services/contact_permissions_service.dart';
import '../../../models/contact_permissions.dart';

/// Viewer-side profile screen.
///
/// - If [contact.contactUserId] is null, the contact is not linked to an app user
///   => show only locally stored contact info.
/// - If linked, we fetch the contact's profile and the *permission row where*
///   owner = contactUserId and viewer = current user.
class ViewContactProfileScreen extends StatefulWidget {
  final app_models.Contact contact;
  const ViewContactProfileScreen({super.key, required this.contact});

  @override
  State<ViewContactProfileScreen> createState() =>
      _ViewContactProfileScreenState();
}

class _ViewContactProfileScreenState extends State<ViewContactProfileScreen> {
  late final ProfileService _profileService;
  late final ContactPermissionsService _permissionsService;

  UserProfile? _profile;
  ContactPermissions? _perms;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _profileService = ProfileService(client);
    _permissionsService = ContactPermissionsService(client);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;

      if (widget.contact.contactUserId == null || currentUserId == null) {
        setState(() {
          _profile = null;
          _perms = null;
        });
        return;
      }

      final ownerId = widget.contact.contactUserId!; // the profile owner
      final viewerId = currentUserId; // me

      final profile = await _profileService.getProfile(ownerId);
      final perms = await _permissionsService.getPermissions(
        ownerId: ownerId,
        viewerId: viewerId,
      );

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _perms = perms;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load contact profile: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool get _canViewBasic {
    final p = _perms;
    if (p == null) return false;
    return p.canViewBasicProfile || p.canViewProfile;
  }

  bool get _canViewMedical {
    final p = _perms;
    if (p == null) return false;
    return p.canViewMedical || p.canViewMedicalInfo || p.canViewEmergencyInfo;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final linked = widget.contact.contactUserId != null;

    // Emergency accent (SOS red) consistent with other screens.
    final emergencyAccent = cs.error;

    return DefaultTabController(
      length: linked ? 2 : 1,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          elevation: 0,
          centerTitle: false,
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          titleSpacing: 12,
          title: const Text(
            'Contact Profile',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight((linked ? 48 : 0) + 1),
            child: Column(
              children: [
                if (linked)
                  TabBar(
                    indicatorColor: emergencyAccent,
                    labelColor: cs.onSurface,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    tabs: const [
                      Tab(text: 'Details'),
                      Tab(text: 'Medical'),
                    ],
                  ),
                Container(height: 1, color: cs.outlineVariant.withOpacity(0.7)),
              ],
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
        body: Column(
          children: [
            _Header(contact: widget.contact),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: emergencyAccent),
                    )
                  : TabBarView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _DetailsTab(
                          contact: widget.contact,
                          profile: _profile,
                          canViewBasic: _canViewBasic,
                          error: _error,
                        ),
                        if (linked)
                          _MedicalTab(
                            profile: _profile,
                            canViewMedical: _canViewMedical,
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final app_models.Contact contact;
  const _Header({required this.contact});

  Color _statusColor(ColorScheme cs, String status) {
    final s = status.trim().toLowerCase();
    if (s == 'accepted' || s == 'active') return cs.primary;
    if (s == 'pending') return cs.tertiary;
    if (s == 'blocked' || s == 'rejected') return cs.error;
    return cs.outline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final statusColor = _statusColor(cs, contact.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.8)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Center(
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  contact.relation ?? 'Emergency contact',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (contact.status.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: statusColor.withOpacity(0.55)),
              ),
              child: Text(
                contact.status,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: statusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final app_models.Contact contact;
  final UserProfile? profile;
  final bool canViewBasic;
  final String? error;

  const _DetailsTab({
    required this.contact,
    required this.profile,
    required this.canViewBasic,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Emergency accent (SOS red)
    final emergencyAccent = cs.error;
    final onEmergencyAccent = cs.onError;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      children: [
        if (error != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.errorContainer.withOpacity(0.55),
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
                    error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onErrorContainer,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        _sectionTitle(theme, 'Contact info'),
        _infoTile(
          context,
          icon: Icons.phone_outlined,
          title: 'Phone',
          value: (contact.phone == null || contact.phone!.trim().isEmpty)
              ? 'Not provided'
              : contact.phone!,
        ),
        _infoTile(
          context,
          icon: Icons.email_outlined,
          title: 'Email',
          value: (contact.email == null || contact.email!.trim().isEmpty)
              ? 'Not provided'
              : contact.email!,
        ),
        _infoTile(
          context,
          icon: Icons.family_restroom_outlined,
          title: 'Relationship',
          value: contact.relation ?? 'Not set',
        ),

        const SizedBox(height: 16),
        _sectionTitle(theme, 'Profile access'),
        Card(
          margin: const EdgeInsets.only(bottom: 12), // ✅ spacing
          elevation: 0,
          color: cs.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      color: canViewBasic ? cs.primary : cs.outline,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        contact.contactUserId == null
                            ? 'This contact is not linked to an in-app profile.'
                            : (canViewBasic
                                  ? 'You can view limited profile details.'
                                  : 'You do not have permission to view profile details.'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface,
                          height: 1.25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (canViewBasic && profile != null) ...[
                  const SizedBox(height: 10),
                  _infoLine(theme, 'Full name', profile!.fullName ?? 'Not set'),
                  _infoLine(
                    theme,
                    'Status',
                    profile!.profileStatus ?? 'Not set',
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: cs.outlineVariant),
                  foregroundColor: cs.onSurface,
                ),
                onPressed: () async {
                  final phone = contact.phone;
                  if (phone == null || phone.trim().isEmpty) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('No phone number available.'),
                      ),
                    );
                    return;
                  }

                  final uri = Uri(scheme: 'tel', path: phone);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        behavior: SnackBarBehavior.floating,
                        content: Text('Could not launch phone app.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.call_rounded),
                label: const Text(
                  'Call',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: emergencyAccent,
                  foregroundColor: onEmergencyAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Chat will be connected later.'),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text(
                  'Chat',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _sectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _infoLine(ThemeData theme, String label, String value) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12), // ✅ spacing between rectangles
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MedicalTab extends StatelessWidget {
  final UserProfile? profile;
  final bool canViewMedical;

  const _MedicalTab({required this.profile, required this.canViewMedical});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (profile == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 12), // ✅ spacing
            elevation: 0,
            color: cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('This contact is not linked to a medical profile.'),
            ),
          ),
        ],
      );
    }

    if (!canViewMedical) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 12), // ✅ spacing
            elevation: 0,
            color: cs.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: cs.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: cs.error),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'You do not have permission to view medical information.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final p = profile!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      children: [
        _medicalTile(
          context,
          'Blood Type',
          p.bloodType ?? 'Not set',
          Icons.bloodtype,
        ),
        _medicalTile(
          context,
          'Allergies',
          p.allergies ?? 'Not set',
          Icons.warning_amber_outlined,
        ),
        _medicalTile(
          context,
          'Chronic Conditions',
          p.chronicConditions ?? 'Not set',
          Icons.healing_outlined,
        ),
        _medicalTile(
          context,
          'Medications',
          p.medications ?? 'Not set',
          Icons.medication_outlined,
        ),
        _medicalTile(
          context,
          'Disabilities',
          p.disabilities ?? 'Not set',
          Icons.accessible_outlined,
        ),
        _medicalTile(
          context,
          'Preferred Hospital',
          p.preferredHospital ?? 'Not set',
          Icons.local_hospital_outlined,
        ),
        _medicalTile(
          context,
          'Other notes',
          p.otherNotes ?? 'Not set',
          Icons.notes_outlined,
        ),
      ],
    );
  }

  Widget _medicalTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12), // ✅ spacing between rectangles
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
