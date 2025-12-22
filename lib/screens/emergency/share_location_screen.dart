import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/location_service.dart';

class ShareLocationScreen extends StatefulWidget {
  const ShareLocationScreen({super.key});

  @override
  State<ShareLocationScreen> createState() => _ShareLocationScreenState();
}

class _ShareLocationScreenState extends State<ShareLocationScreen> {
  final LocationService _locationService = LocationService();

  Position? _position;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshLocation();
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final pos = await _locationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _position = pos;
        if (pos == null) {
          _error = 'Unable to get location. Check GPS and permissions.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error getting location: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _shareWithEmergencyServices() {
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No location yet – try refreshing first.'),
        ),
      );
      return;
    }

    // call EmergencyRequestService
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Location shared: ${_position!.latitude}, ${_position!.longitude}',
        ),
      ),
    );
  }

  void _shareWithContacts() {
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No location yet – try refreshing first.'),
        ),
      );
      return;
    }

    // integrate "share_plus" or send to contacts.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Location ready to share with contacts: '
          '${_position!.latitude}, ${_position!.longitude}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latText = _position != null
        ? _position!.latitude.toStringAsFixed(5)
        : 'Unknown';
    final lngText = _position != null
        ? _position!.longitude.toStringAsFixed(5)
        : 'Unknown';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Location'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE0E9FF), Color(0xFFF5E6FF)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Icon(Icons.near_me, size: 60, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Current Location',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_loading) ...[
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ] else if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ] else ...[
                  Text('Latitude: $latText'),
                  Text('Longitude: $lngText'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _refreshLocation,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Location'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _shareWithEmergencyServices,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Share with Emergency Services'),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2962FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _shareWithContacts,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Share with Contacts'),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Sharing your location helps emergency responders reach you faster. '
              'Your location is only shared when you tap one of the buttons above.',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
