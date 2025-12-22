
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/contact.dart';
import '../../models/user_profile.dart';

// import '../../models/contact_permissions.dart';

import '../../services/profile_service.dart';
import '../../services/contact_permissions_service.dart';
import 'package:emergency_alert/models/contact_permissions.dart';
// import 'package:emergency_alert/services/profile_service.dart';
// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../models/contact.dart';
// import '../../models/user_profile.dart';
// import '../../models/contact_permissions.dart';
// import '../../services/profile_service.dart';
// import '../../services/contact_permissions_service.dart';
// import '../../models/contact_permissions.dart';

class ViewContactProfileScreen extends StatefulWidget {
  final Contact contact;
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

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _profileService = ProfileService(client);
    _permissionsService = ContactPermissionsService(client);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      UserProfile? profile;
      ContactPermissions? perms;

      if (widget.contact.contactUserId != null && currentUserId != null) {
        final contactUserId = widget.contact.contactUserId!;
        profile = await _profileService.getProfile(contactUserId);
        perms = await _permissionsService.getPermissions(
          ownerId: currentUserId,
          contactUserId: contactUserId,
        );
      }

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _perms = perms;
      });
    } catch (_) {
      // ignore for now or show error
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Details, Medical Info
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F5F7),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ],
        ),
        body: Column(
          children: [
            _header(widget.contact),
            const TabBar(
              indicatorColor: Color(0xFF15664F),
              labelColor: Color(0xFF15664F),
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: 'Details'),
                Tab(text: 'Medical Info'),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _DetailsTab(contact: widget.contact, profile: _profile),
                        _MedicalTab(profile: _profile, perms: _perms),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(Contact c) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          CircleAvatar(
            radius: 40,
            child: Text(
              c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 26),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            c.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            c.relation ?? 'Emergency contact',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final Contact contact;
  final UserProfile? profile;

  const _DetailsTab({required this.contact, this.profile});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Contact info'),
        _infoRow(Icons.phone, 'Phone', contact.phone ?? 'Not provided'),
        if (contact.email != null && contact.email!.isNotEmpty)
          _infoRow(Icons.email_outlined, 'Email', contact.email!),
        if (profile?.fullName != null)
          _infoRow(Icons.person_outline, 'Profile name', profile!.fullName!),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: call via url_launcher
                },
                icon: const Icon(Icons.call_rounded),
                label: const Text('Call'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15664F),
                ),
                onPressed: () {
                  // TODO: open chat screen
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Chat'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
  );

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _MedicalTab extends StatelessWidget {
  final UserProfile? profile;
  final ContactPermissions? perms;

  const _MedicalTab({this.profile, this.perms});

  bool get _allowed {
    if (perms == null) return false;
    return perms!.canViewMedical || perms!.canViewEmergencyInfo;
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Center(
        child: Text('This contact is not linked to a profile.'),
      );
    }

    if (!_allowed) {
      return const Center(
        child: Text(
          'You do not have permission to view this contact\'s medical info.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final p = profile!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _gridTile('Blood Type', p.bloodType ?? 'Unknown', Icons.bloodtype),
        _gridTile('Allergies', p.allergies ?? 'None', Icons.warning_amber),
        _gridTile(
          'Chronic Conditions',
          p.chronicConditions ?? 'None',
          Icons.healing,
        ),
        _gridTile(
          'Medications',
          p.medications ?? 'None',
          Icons.medication_outlined,
        ),
        _gridTile('Disabilities', p.disabilities ?? 'None', Icons.accessible),
        _gridTile(
          'Preferred Hospital',
          p.preferredHospital ?? 'Not set',
          Icons.local_hospital,
        ),
      ],
    );
  }

  Widget _gridTile(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
