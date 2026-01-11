import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};

  static const CameraPosition _fallbackCamera = CameraPosition(
    target: LatLng(30.0444, 31.2357), // Cairo fallback
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _refreshLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
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
      });

      _updateMapUI();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error getting location: $e';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updateMapUI() {
    final p = _position;
    if (p == null) return;

    final latLng = LatLng(p.latitude, p.longitude);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    setState(() {
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('me'),
            position: latLng,
            infoWindow: const InfoWindow(title: 'You are here'),
          ),
        );

      // Accuracy circle (use theme accent instead of hardcoded blue)
      _circles
        ..clear()
        ..add(
          Circle(
            circleId: const CircleId('accuracy'),
            center: latLng,
            radius: (p.accuracy.isNaN ? 30.0 : p.accuracy).clamp(10.0, 120.0),
            strokeWidth: 2,
            strokeColor: cs.primary.withOpacity(0.55),
            fillColor: cs.primary.withOpacity(0.12),
          ),
        );
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: 16)),
    );
  }

  void _shareWithEmergencyServices() {
    if (_position == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('No location yet – try refreshing first.'),
        ),
      );
      return;
    }

    // TODO: call EmergencyRequestService here
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Location shared: ${_position!.latitude}, ${_position!.longitude}',
        ),
      ),
    );
  }

  void _shareWithContacts() {
    if (_position == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('No location yet – try refreshing first.'),
        ),
      );
      return;
    }

    // TODO: integrate share_plus or your contacts flow
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Location ready to share with contacts: '
          '${_position!.latitude}, ${_position!.longitude}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Emergency accent (SOS red)
    final emergencyAccent = cs.error;

    final latText = _position != null
        ? _position!.latitude.toStringAsFixed(5)
        : 'Unknown';
    final lngText = _position != null
        ? _position!.longitude.toStringAsFixed(5)
        : 'Unknown';

    final initialCamera = _position == null
        ? _fallbackCamera
        : CameraPosition(
            target: LatLng(_position!.latitude, _position!.longitude),
            zoom: 16,
          );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        titleSpacing: 12,
        title: const Text(
          'Share Location',
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
        children: [
          // Map card
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outlineVariant),
            ),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 240,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: initialCamera,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    compassEnabled: true,
                    zoomControlsEnabled: false,
                    markers: _markers,
                    circles: _circles,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      _updateMapUI();
                    },
                  ),
                  // Small action button in-map
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'center_me',
                      backgroundColor: cs.surfaceContainerHighest,
                      foregroundColor: cs.onSurface,
                      onPressed: () {
                        if (_position == null) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              behavior: SnackBarBehavior.floating,
                              content: Text('No location yet – refresh first.'),
                            ),
                          );
                          return;
                        }
                        _updateMapUI();
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),

                  // Loading overlay (nice emergency-app feel)
                  if (_loading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.10),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: emergencyAccent,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Coordinates / status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your Current Location',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: _loading ? null : _refreshLocation,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(16),
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
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latitude: $latText',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Longitude: $lngText',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Refresh button (outlined, consistent)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: cs.outlineVariant),
              foregroundColor: cs.onSurface,
            ),
            onPressed: _loading ? null : _refreshLocation,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Refresh Location',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),

          const SizedBox(height: 14),

          // Emergency share (red)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: emergencyAccent,
              foregroundColor: cs.onError,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _shareWithEmergencyServices,
            icon: const Icon(Icons.sos_rounded),
            label: const Text(
              'Share with Emergency Services',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),

          const SizedBox(height: 10),

          // Contacts share (primary)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _shareWithContacts,
            icon: const Icon(Icons.group_outlined),
            label: const Text(
              'Share with Contacts',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),

          const SizedBox(height: 14),

          // Info / disclaimer card (no hardcoded yellow)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withOpacity(0.7),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sharing your location helps emergency responders reach you faster. '
                    'Your location is only shared when you tap one of the buttons above.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      height: 1.35,
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
