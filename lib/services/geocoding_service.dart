import 'package:geocoding/geocoding.dart';

class GeocodingService {
  Future<String?> reverseGeocode(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) return null;

    final p = placemarks.first;

    final parts = <String>[
      if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
      if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
      if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
      if ((p.administrativeArea ?? '').trim().isNotEmpty)
        p.administrativeArea!.trim(),
      if ((p.country ?? '').trim().isNotEmpty) p.country!.trim(),
    ];

    return parts.isEmpty ? null : parts.join(', ');
  }
}
