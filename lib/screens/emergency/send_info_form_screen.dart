import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/emergency_service.dart';
import '../../services/emergency_request_service.dart';

import 'package:emergency_alert/services/location_service.dart';

class SendInfoFormScreen extends StatefulWidget {
  final EmergencyService service;

  const SendInfoFormScreen({super.key, required this.service});

  @override
  State<SendInfoFormScreen> createState() => _SendInfoFormScreenState();
}

class _SendInfoFormScreenState extends State<SendInfoFormScreen> {
  final _pageController = PageController();
  int _step = 0;

  final _locationCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _sending = false;
  String _buildEmergencyReport({
    required String type,
    required String phone,
    required String manualLocation,
    required String details,
    required double? lat,
    required double? lng,
  }) {
    final gps = (lat != null && lng != null)
        ? "Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}"
        : "Location not shared";

    return [
      "EMERGENCY REPORT",
      "Type: $type",
      "Caller Phone: ${phone.isEmpty ? "Not provided" : phone}",
      "Manual Location: ${manualLocation.isEmpty ? "Not provided" : manualLocation}",
      "Live GPS: $gps",
      "What happened: ${details.isEmpty ? "Not provided" : details}",
      "Timestamp: ${DateTime.now().toIso8601String()}",
    ].join("\n");
  }

  @override
  void dispose() {
    _pageController.dispose();
    _locationCtrl.dispose();
    _detailsCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < 2) {
      setState(() => _step++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _sending = true);

    final requestService = EmergencyRequestService(Supabase.instance.client);

    try {
      final phone = _phoneCtrl.text.trim();
      final details = _detailsCtrl.text.trim();
      final manualLocation = _locationCtrl.text.trim();

      // 1) GPS
      double? lat;
      double? lng;
      try {
        final pos = await LocationService().getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {
        lat = null;
        lng = null; // do NOT block emergency submission
      }

      // 2) Structured report saved in "notes"
      final report = _buildEmergencyReport(
        type: widget.service.type.name,
        phone: phone,
        manualLocation: manualLocation,
        details: details,
        lat: lat,
        lng: lng,
      );

      // 3) Insert into Supabase (emergencies table)
      await requestService.sendRequest(
        service: widget.service,
        phone: phone,
        description: report,
        latitude: lat,
        longitude: lng,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Information sent successfully')),
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
  Widget build(BuildContext context) {
    final stepTitles = ['Patient Location', 'What Happened?', 'Contact Info'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.service.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            "We're Here to Help",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text('Take your time. Answer what you can.'),

          const SizedBox(height: 12),

          // progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LinearProgressIndicator(
              value: (_step + 1) / 3,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 8),
          Text('Step ${_step + 1} of 3'),

          const SizedBox(height: 8),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _stepCard(
                  title: 'Patient Location *',
                  hint: 'Where is the patient?',
                  controller: _locationCtrl,
                ),
                _stepCard(
                  title: 'What happened? *',
                  hint: 'Describe the emergency briefly',
                  controller: _detailsCtrl,
                  maxLines: 5,
                ),
                _stepCard(
                  title: 'Contact Phone *',
                  hint: 'Your phone number',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _sending
                        ? null
                        : () {
                            Navigator.pop(context);
                          },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sending ? null : _nextStep,
                    child: Text(_step == 2 ? 'Send' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepCard({
    required String title,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.white,
        elevation: 0,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: title,
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      ),
    );
  }
}
