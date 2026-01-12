import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Model representing a responder with their estimated time of arrival
class ResponderETA {
  final int responderId;
  final int estimatedTimeSeconds; // ETA in seconds as an integer

  const ResponderETA({
    required this.responderId,
    required this.estimatedTimeSeconds,
  });
}

/// Service that provides ETAs for responders to a given emergency location.
///
/// Usage:
/// ```dart
/// final etas = await EstimatedTimeArrivalService().fetchResponderETAs(
///   emergencyLat: 37.7749,
///   emergencyLng: -122.4194,
///   emergencyType: 'ambulance',
/// );
/// ```
class EstimatedTimeArrivalService {
  final SupabaseClient _supabase;
  final String _googleMapsApiKey;

  EstimatedTimeArrivalService({
    SupabaseClient? supabaseClient,
    String? googleMapsApiKey,
  }) : _supabase = supabaseClient ?? Supabase.instance.client,
       _googleMapsApiKey = googleMapsApiKey ?? dotenv.get('GOOGLE_MAPS_KEY');

  /// Returns a list of ResponderETA sorted from smallest to largest ETA.
  Future<List<ResponderETA>> fetchResponderETAs({
    required double emergencyLat,
    required double emergencyLng,
    required String emergencyType,
  }) async {
    try {
    // 1) Fetch available responders from Supabase matching the emergency type
      debugPrint('Fetching responders for type: $emergencyType');
      final responders = await _supabase
        .from('responders')
        .select('id, lat, long, type')
        .eq('type', emergencyType)
        .eq('status', 'open');

    if (responders.isEmpty) {
        debugPrint('No responders found for type: $emergencyType');
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
            if (lat == null || lng == null) {
              debugPrint('Responder ${r['id']} has invalid lat/lng');
              return null;
            }
            return {
              "waypoint": {
                "location": {
                  "latLng": {"latitude": lat, "longitude": lng},
                },
              },
            };
        })
          .whereType<Map<String, dynamic>>()
          .toList();

    if (origins.isEmpty) {
        debugPrint('No valid origins after filtering');
      return [];
    }
      debugPrint('Built ${origins.length} origins');

      final destinations = [
        {
          "waypoint": {
            "location": {
              "latLng": {"latitude": emergencyLat, "longitude": emergencyLng},
            },
          },
        },
      ];

      // 3) Call Google Routes Compute Route Matrix API
    final url = Uri.parse(
        'https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix',
      );

      final body = {
        "origins": origins,
        "destinations": destinations,
        "travelMode": "DRIVE",
        "routingPreference": "TRAFFIC_AWARE",
      };

      debugPrint(
        'Sending request to Routes API with body: ${json.encode(body)}',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _googleMapsApiKey,
          'X-Goog-FieldMask':
              'originIndex,destinationIndex,duration,distanceMeters,status,condition',
        },
        body: json.encode(body),
    );

      debugPrint('API response status: ${response.statusCode}');
      debugPrint('API response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
          'Compute Route Matrix API error: ${response.statusCode} - ${response.body}',
      );
    }

      final data = json.decode(response.body) as List<dynamic>;
      debugPrint('Parsed ${data.length} route elements');

    // 4) Map responders to their ETAs
    final responderETAs = <ResponderETA>[];

      for (final element in data) {
        final map = element as Map<String, dynamic>;
        final status = map['status'] as Map<String, dynamic>?;
        final condition = map['condition'] as String?;

        if (status != null && status.isNotEmpty) {
          debugPrint('Skipping element with status: $status');
          continue;
        }
        if (condition != 'ROUTE_EXISTS') {
          debugPrint('Skipping element with condition: $condition');
          continue;
        }

        final originIndex = map['originIndex'] as int;
        final durationStr = map['duration'] as String?;
        if (durationStr == null) {
          debugPrint('Skipping element with no duration');
          continue;
        }

        final durationSeconds = int.parse(durationStr.replaceAll('s', ''));

        final responder = respondersList[originIndex] as Map<String, dynamic>;
        final responderId = responder['id'] as int;

          responderETAs.add(
            ResponderETA(
              responderId: responderId,
              estimatedTimeSeconds: durationSeconds,
            ),
          );
        }

      debugPrint('Found ${responderETAs.length} valid ETAs');

    // 5) Sort by estimated time (smallest to largest)
    responderETAs.sort(
      (a, b) => a.estimatedTimeSeconds.compareTo(b.estimatedTimeSeconds),
    );

    return responderETAs;
    } catch (e, stackTrace) {
      debugPrint('Error in fetchResponderETAs: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
