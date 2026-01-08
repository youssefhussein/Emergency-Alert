import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/emergency_service.dart';
import '../../services/emergency_request_service.dart';

import '../../services/location_service.dart';
import '../../services/geocoding_service.dart';

class SendInfoFormScreen extends StatefulWidget {
  final EmergencyService service;

  const SendInfoFormScreen({super.key, required this.service});

  @override
  State<SendInfoFormScreen> createState() => _SendInfoFormScreenState();
}

class _SendInfoFormScreenState extends State<SendInfoFormScreen> {
  final _locationCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // UI-only toggles (wiring to DB/storage comes later)
  bool _shareLocation = true;
  bool _notifyTrustedContacts = false;

  // UI-only voice note placeholder (no real recording yet)
  bool _hasVoiceNote = false;

  bool _sending = false;

  double? _lat;
  double? _lng;

  bool _loadingLocation = true;
  String? _locationError;

  String? _detectedAddress; // pretty address shown in card

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      final pos = await LocationService().getCurrentPosition();
      _lat = pos.latitude;
      _lng = pos.longitude;

      // Reverse geocode into a nice address string
      String? address;
      try {
        address = await GeocodingService().reverseGeocode(_lat!, _lng!);
      } catch (_) {
        address = null; // do not block
      }

      _detectedAddress = (address != null && address.trim().isNotEmpty)
          ? address.trim()
          : null;

      // If user hasn't typed a manual location yet, fill it with detected address.
      // If geocoding fails, fill with GPS coords as a fallback.
      if (_locationCtrl.text.trim().isEmpty) {
        _locationCtrl.text =
            _detectedAddress ??
            "Lat: ${_lat!.toStringAsFixed(6)}, Lng: ${_lng!.toStringAsFixed(6)}";
      }
    } catch (e) {
      _lat = null;
      _lng = null;
      _detectedAddress = null;
      _locationError = "Couldn't detect location. You can type it manually.";
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  String _buildEmergencyReport({
    required String type,
    required String phone,
    required String manualLocation,
    required String details,
    required double? lat,
    required double? lng,
    required String? detectedAddress,
  }) {
    final gps = (lat != null && lng != null)
        ? "Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}"
        : "Location not shared";

    return [
      "EMERGENCY REPORT",
      "Type: $type",
      "Caller Phone: ${phone.isEmpty ? "Not provided" : phone}",
      "Detected Address: ${detectedAddress?.isNotEmpty == true ? detectedAddress : "Not available"}",
      "Manual Location: ${manualLocation.isEmpty ? "Not provided" : manualLocation}",
      "Live GPS: $gps",
      "What happened: ${details.isEmpty ? "Not provided" : details}",
      "Timestamp: ${DateTime.now().toIso8601String()}",
    ].join("\n");
  }

  Future<void> _submit() async {
    setState(() => _sending = true);

    final requestService = EmergencyRequestService(Supabase.instance.client);

    try {
      final phone = _phoneCtrl.text.trim();
      final details = _detailsCtrl.text.trim();
      final manualLocation = _locationCtrl.text.trim();

      // If GPS not available yet, try once more quickly (do NOT block if fails).
      double? lat = _lat;
      double? lng = _lng;
      String? detectedAddress = _detectedAddress;

      if (lat == null || lng == null) {
        try {
          final pos = await LocationService().getCurrentPosition();
          lat = pos.latitude;
          lng = pos.longitude;

          try {
            detectedAddress = await GeocodingService().reverseGeocode(lat, lng);
          } catch (_) {
            // ignore
          }
        } catch (_) {
          lat = null;
          lng = null;
        }
      }

      final report = _buildEmergencyReport(
        type: widget.service.type.name,
        phone: phone,
        manualLocation: manualLocation,
        details: details,
        lat: lat,
        lng: lng,
        detectedAddress: detectedAddress,
      );

      await requestService.sendRequest(
        service: widget.service,
        phone: phone,
        description: report,
        latitude: lat,
        longitude: lng,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency request sent successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _detailsCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    final title = "${widget.service.name} Emergency";

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: Text(title),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            "Provide emergency details",
            style: theme.textTheme.bodySmall?.copyWith(
              color: c.onSurfaceVariant,
            ),
          ),

          // const SizedBox(height: 12),
          const SizedBox(height: 16),

          Text(
            "What's happening? (Optional)",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _detailsCtrl,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: "Brief description to help responders prepare...",
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: c.primary, width: 1.2),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),

          const SizedBox(height: 6),
          Text(
            "Keep it brief. AI will analyze and categorize automatically.",
            style: theme.textTheme.bodySmall?.copyWith(
              color: c.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            "Add Photo (Optional)",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          _photoPickerPlaceholder(context),

          const SizedBox(height: 14),

          // NEW: Optional extras (UI only for now)
          _voiceNoteSection(context),

          const SizedBox(height: 10),
          _toggleCard(
            context,
            icon: Icons.location_on_outlined,
            title: "Share Location",
            subtitle: "Help responders find you faster",
            value: _shareLocation,
            onChanged: (v) => setState(() => _shareLocation = v),
          ),
          const SizedBox(height: 10),
          _toggleCard(
            context,
            icon: Icons.group_outlined,
            title: "Notify Trusted Contacts",
            subtitle: "Alert your emergency contacts",
            value: _notifyTrustedContacts,
            onChanged: (v) => setState(() => _notifyTrustedContacts = v),
          ),

          const SizedBox(height: 16),

          _aiDispatchInfo(context),

          const SizedBox(height: 90),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _sending ? null : _submit,
              child: _sending
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      "Request Emergency Help",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _voiceNoteSection(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Add Voice Note (Optional)",
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // UI-only behavior: toggle a "voice note added" state so you can validate the design.
            setState(() => _hasVoiceNote = !_hasVoiceNote);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _hasVoiceNote
                      ? "Voice note added (UI only)"
                      : "Voice note removed (UI only)",
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.outlineVariant),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(Icons.mic_none_outlined, color: c.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _hasVoiceNote
                        ? "Voice note added (tap to remove)"
                        : "Tap to record voice note",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: c.onSurface,
                    ),
                  ),
                ),
                if (_hasVoiceNote)
                  Icon(Icons.check_circle_outline, color: c.primary)
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: c.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _toggleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.outlineVariant),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: c.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _photoPickerPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo picker not wired yet')),
        );
      },
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.outlineVariant),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_camera_outlined, color: c.onSurfaceVariant),
              const SizedBox(height: 8),
              Text(
                "Tap to add photo",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: c.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aiDispatchInfo(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;

    final bg = c.primaryContainer.withOpacity(0.25);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.primary.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: c.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI-Powered Dispatch",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Our AI will instantly analyze your emergency, determine severity, and automatically dispatch the nearest available responder. No approval needed.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.onSurfaceVariant,
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
