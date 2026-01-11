import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Model representing a responder with their estimated time of arrival
class ResponderETA {
  final int responderId;
  final int estimatedTimeSeconds; // ETA in seconds as an integer

  const ResponderETA({
    required this.responderId,
    required this.estimatedTimeSeconds,
  });
}

/// Provider that returns a list of responder IDs sorted by estimated time of arrival
/// from smallest to largest time, along with their estimated time in seconds.
///
/// Parameters: (emergencyLat, emergencyLng, emergencyType)
/// - emergencyLat: Latitude of the emergency location
/// - emergencyLng: Longitude of the emergency location
/// - emergencyType: Type of emergency (ambulance, fire, police, hospital, car)
///
/// Usage:
/// ```dart
/// final etas = ref.watch(responderETAsProvider((
///   37.7749,  // emergencyLat
///   -122.4194, // emergencyLng
///   'ambulance', // emergencyType
/// )));
/// ```
final responderETAsProvider = FutureProvider.family<
    List<ResponderETA>,
    (double, double, String)>(
  (ref, params) async {
    final emergencyLat = params.$1;
    final emergencyLng = params.$2;
    final emergencyType = params.$3;
    final supabase = Supabase.instance.client;
    final apiKey = dotenv.get('GOOGLE_MAPS_API_KEY');

    // 1) Fetch available responders from Supabase matching the emergency type
    final responders = await supabase
        .from('responders')
        .select('id, lat, long, type')
        .eq('type', emergencyType)
        .eq('status', 'open');

    if (responders.isEmpty) {
      return [];
    }

    final respondersList = responders as List<dynamic>;

    // 2) Build origins and destinations for Distance Matrix API
    // Origins: all responder locations (where they're coming from)
    // Destination: emergency location (where they need to go)
    final origins = respondersList
        .map((r) {
          final lat = (r['lat'] as num?)?.toDouble();
          final lng = (r['long'] as num?)?.toDouble();
          if (lat == null || lng == null) return null;
          return '$lat,$lng';
        })
        .whereType<String>()
        .join('|');

    if (origins.isEmpty) {
      return [];
    }

    final destination = '$emergencyLat,$emergencyLng';

    // 3) Call Google Maps Distance Matrix API
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
      '?origins=${Uri.encodeComponent(origins)}'
      '&destinations=${Uri.encodeComponent(destination)}'
      '&mode=driving'
      '&departure_time=now'
      '&traffic_model=best_guess'
      '&key=$apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Distance Matrix API error: ${response.statusCode} - ${response.body}',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    // Check for API errors
    if (data['status'] != 'OK') {
      throw Exception('Distance Matrix API error: ${data['status']}');
    }

    final rows = data['rows'] as List<dynamic>;
    if (rows.isEmpty) {
      return [];
    }

    final elements = rows.first['elements'] as List<dynamic>;

    // 4) Map responders to their ETAs
    final responderETAs = <ResponderETA>[];

    for (int i = 0; i < elements.length && i < respondersList.length; i++) {
      final element = elements[i] as Map<String, dynamic>;
      final status = element['status'] as String?;

      // Only include responders with valid routes
      if (status == 'OK') {
        final responder = respondersList[i] as Map<String, dynamic>;
        final responderId = responder['id'] as int;

        // Prefer duration_in_traffic if available, otherwise use duration
        final durationObj = element['duration_in_traffic'] as Map<String, dynamic>? ??
            element['duration'] as Map<String, dynamic>?;

        if (durationObj != null) {
          final durationSeconds = (durationObj['value'] as num).toInt();
          responderETAs.add(
            ResponderETA(
              responderId: responderId,
              estimatedTimeSeconds: durationSeconds,
            ),
          );
        }
      }
    }

    // 5) Sort by estimated time (smallest to largest)
    responderETAs.sort(
      (a, b) => a.estimatedTimeSeconds.compareTo(b.estimatedTimeSeconds),
    );

    return responderETAs;
  },
);
