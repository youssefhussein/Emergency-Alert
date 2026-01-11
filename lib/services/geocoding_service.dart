import 'package:emergency_alert/models/geocode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:geocoding/geocoding.dart';

import 'package:http/http.dart';

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


  Future<String> geocodeAPI(double lat, double lng) async {
    final apiKey = dotenv.get('GEOCODE_API');


    final url = 'https://api.geocode.ai/v1/reverse?key=$apiKey&point.lat=$lat&point.lon=$lng';

    final response = await get(Uri.parse(url));
    if (response.statusCode == 200) {
      final reverseGeocode = ReverseGeocode.fromRawJson(response.body);
      if (reverseGeocode.features.isNotEmpty) {
        final properties = reverseGeocode.features.first.properties;
        return properties.label;
      } else {
        throw Exception('No features found in geocoding response.');
      }
    } else {
      throw Exception('Failed to fetch geocode: ${response.statusCode}');
    }
  }
}


