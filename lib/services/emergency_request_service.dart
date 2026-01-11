import 'dart:typed_data';
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'emergency_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';

class EmergencyRequestService {
  final SupabaseClient _supabase;

  EmergencyRequestService(this._supabase);
  Future<int> sendRequest({
    required EmergencyService service,
    String? userId,

    String? description,

    String? phone,

    double? latitude,
    double? longitude,
    bool shareLocation = true,
    bool notifyContacts = false,
    String? locationDetails,

    /// Stored in Supabase Storage bucket `emergency-media`
    Uint8List? photoBytes,
    String? photoExt, // e.g. "jpg", "png"
    String? photoContentType, // e.g. "image/jpeg"
    /// Stored in Supabase Storage bucket `emergency-media`
    Uint8List? voiceBytes,
    String? voiceExt, // e.g. "m4a", "wav"
    String? voiceContentType, // e.g. "audio/mp4"
    int? voiceDurationSec,
  }) async {
    final effectiveUserId = userId ?? _supabase.auth.currentUser?.id;
    if (effectiveUserId == null) {
      throw Exception("No authenticated user. Login required.");
    }

    // 1) Insert emergency row and return id
    final inserted = await _supabase
        .from('emergencies')
        .insert({
          'user_id': effectiveUserId,
          'type': service.type.name,
          'status': 'open',
          'phone': phone,
          'notes': description,
          'share_location': shareLocation,
          'notify_contacts': notifyContacts,
          'location_details': locationDetails,
          'location_lat': shareLocation ? latitude : null,
          'location_lng': shareLocation ? longitude : null,
        })
        .select('id')
        .single();

    final emergencyId = inserted['id'] as int;

    // 2) Upload optional media
    String? photoPath;
    String? voicePath;

    if (photoBytes != null) {
      final ext = _cleanExt(photoExt, fallback: 'jpg');
      photoPath = '$effectiveUserId/emergencies/$emergencyId/photo.$ext';

      await _supabase.storage
          .from('emergency-media')
          .uploadBinary(
            photoPath,
            photoBytes,
            fileOptions: FileOptions(
              contentType: photoContentType ?? _guessImageContentType(ext),
              upsert: true,
            ),
          );
    }

    if (voiceBytes != null) {
      final ext = (voiceExt ?? 'wav').replaceAll('.', '');
      voicePath = '$effectiveUserId/emergencies/$emergencyId/voice.$ext';

      await _supabase.storage
          .from('emergency-media')
          .uploadBinary(
            voicePath,
            voiceBytes,
            fileOptions: FileOptions(
              contentType: voiceContentType ?? 'audio/wav',
              upsert: true,
            ),
          );
    }

    // 3) Update emergency row with storage paths (and duration)
    final update = <String, dynamic>{};
    if (photoPath != null) update['photo_url'] = photoPath;

    if (voicePath != null) update['voice_note_url'] = voicePath;
    if (voiceDurationSec != null) {
      update['voice_note_duration_sec'] = voiceDurationSec;
    }

    if (update.isNotEmpty) {
      await _supabase.from('emergencies').update(update).eq('id', emergencyId);
    }
 
    // 4) Generate AI report
    _generateAndSaveReport(
      emergencyId: emergencyId,
      userId: effectiveUserId,
      emergencyType: service.type.name,
      notes: description,
      phone: phone,
      shareLocation: shareLocation,
      latitude: latitude,
      longitude: longitude,
      locationDetails: locationDetails,
      photoPath: photoPath,
      voicePath: voicePath,
      voiceDurationSec: voiceDurationSec,
    );

    // 5) Assign a responder to the emergency using Firebase AI
    _assignResponder(
      emergencyId: emergencyId,
      emergencyType: service.type.name,
      description: description,
      locationDetails: locationDetails,
      latitude: latitude,
      longitude: longitude,
      photoBytes: photoBytes,
      photoContentType: photoContentType,
      voiceBytes: voiceBytes,
      voiceContentType: voiceContentType,
    );

    return emergencyId;
  }

  String _cleanExt(String? ext, {required String fallback}) {
    final e = (ext ?? '').trim().toLowerCase();
    if (e.isEmpty) return fallback;
    return e.startsWith('.') ? e.substring(1) : e;
  }

  Future<void> _generateAndSaveReport({
    required int emergencyId,
    required String userId,
    required String emergencyType,
    required String? notes,
    required String? phone,
    required bool shareLocation,
    required double? latitude,
    required double? longitude,
    required String? locationDetails,
    required String? photoPath,
    required String? voicePath,
    required int? voiceDurationSec,
  }) async {
    try {
      // 1) Fetch user profile from Supabase (edit fields to match your table)
      final profile = await _supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();

      // 2) Gemini model via Firebase AI (same approach as your chatbot)
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash-lite',
        systemInstruction: Content.text(
          "You are an emergency incident report writer. "
          "Use ONLY the provided info. Do NOT invent facts. "
          "If something is missing, write 'Unknown'. "
          "Output plain text with headings:\n"
          "Summary\nUser Info\nLocation\nDetails\nAttachments\nMissing Info\n",
        ),
        generationConfig: GenerationConfig(maxOutputTokens: 600),
      );

      // 3) Build prompt (profile + emergency info + attachment paths)
      final prompt =
          """
Write an incident report.

User Info (from database):
- Full name: ${profile['full_name'] ?? 'Unknown'}
- Phone: ${profile['phone'] ?? phone ?? 'Unknown'}
- Blood type: ${profile['blood_type'] ?? 'Unknown'}
- Allergies: ${profile['allergies'] ?? 'Unknown'}
- Chronic conditions: ${profile['chronic_conditions'] ?? 'Unknown'}
- Medications: ${profile['medications'] ?? 'Unknown'}
- Other notes: ${profile['other_notes'] ?? profile['otherNotes'] ?? 'Unknown'}

Emergency Request:
- Emergency ID: $emergencyId
- Type: $emergencyType
- Notes: ${notes ?? 'Unknown'}
- Share location: $shareLocation
- Latitude: ${latitude ?? 'Unknown'}
- Longitude: ${longitude ?? 'Unknown'}
- Location details: ${locationDetails ?? 'Unknown'}

Attachments (paths in Supabase Storage):
- Photo path: ${photoPath ?? 'None'}
- Voice path: ${voicePath ?? 'None'}
- Voice duration (sec): ${voiceDurationSec ?? 'Unknown'}

Rules:
- Do not diagnose medically.
- Do not guess unknown facts.
- Include a "Missing Info" list for anything unclear.
""";

      // 4) Generate report text
      final res = await model.generateContent([Content.text(prompt)]);
      final reportText = (res.text ?? '').trim();

      if (reportText.isEmpty) {
        debugPrint("AI report empty for emergencyId=$emergencyId");
        return;
      }

      // 5) Save report to Supabase
      await _supabase
          .from('emergencies')
          .update({'report_by_ai': reportText})
          .eq('id', emergencyId);

      debugPrint("✅ AI report saved for emergencyId=$emergencyId");
    } catch (e) {
      debugPrint("❌ AI report generation failed: $e");
    }
  }

  Future<void> _assignResponder({
    required int emergencyId,
    required String emergencyType,
    required String? description,
    required String? locationDetails,
    required double? latitude,
    required double? longitude,
    required Uint8List? photoBytes,
    required String? photoContentType,
    required Uint8List? voiceBytes,
    required String? voiceContentType,
  }) async {
    try {
      // 1) Fetch available responders from Supabase
      final responders = await _supabase
          .from('responders')
          .select('id, uuid,type, lat, long, institute_name, address_name, status')
          // .eq('type', emergencyType)
          .eq('status', 'open');

      if (responders.isEmpty) {
        debugPrint("⚠️ No available responders found for type=$emergencyType");
        return;
      }

      final respondersList = responders as List<dynamic>;
      debugPrint("📋 Found ${respondersList.length} available responders");

      // 2) Build responder list text for AI prompt
      final respondersText = respondersList
          .asMap()
          .entries
          .map((entry) {
            final idx = entry.key;
            final r = entry.value as Map<String, dynamic>;
            return 'Responder ${idx + 1}:\n'
                '- ID: ${r['id']}\n'
                '- Institute: ${r['institute_name'] ?? 'Unknown'}\n'
                '- Address: ${r['address_name'] ?? 'Unknown'}\n'
                '- Location: Lat ${r['lat']}, Lon ${r['lon']}\n';
          })
          .join('\n');

      // 3) Calculate distances if location is available
      String distanceInfo = '';
      if (latitude != null && longitude != null) {
        distanceInfo = '\n\nDistance calculations (for reference):\n';
        for (final r in respondersList) {
          final resp = r as Map<String, dynamic>;
          final respLat = (resp['lat'] as num?)?.toDouble();
          final respLon = (resp['lon'] as num?)?.toDouble();
          if (respLat != null && respLon != null) {
            final distance = _calculateDistance(
              latitude,
              longitude,
              respLat,
              respLon,
            );
            distanceInfo +=
                '- Responder ID ${resp['id']}: ${distance.toStringAsFixed(2)} km\n';
          }
        }
      }

      // 4) Build prompt
      final prompt = """
You are an emergency dispatch system. Analyze this emergency request and assign the most appropriate responder from the available list.

Emergency Details:
- Emergency ID: $emergencyId
- Type: $emergencyType
- Description: ${description ?? 'No description provided'}
- Location Details: ${locationDetails ?? 'No additional location details'}
- Emergency Location: ${latitude != null && longitude != null ? 'Lat $latitude, Lon $longitude' : 'Location not shared'}
$distanceInfo

Available Responders:
$respondersText

Instructions:
1. Consider the emergency type, description, and location
2. Prioritize proximity to the emergency location (if available)
3. Consider the nature of the emergency when selecting the responder
4. Return ONLY the responder ID (as an integer) that should be assigned
5. If no suitable responder is found, return "NONE"

Your response must be ONLY the responder ID number (e.g., "42") or "NONE" if no responder can be assigned.
""";

      // 5) Build content parts (text + optional image + optional audio)
      final parts = <Part>[TextPart(prompt)];

      if (photoBytes != null) {
        // Use provided content type or default to jpeg
        final imageMimeType = photoContentType ?? 'image/jpeg';
        parts.add(InlineDataPart(imageMimeType, photoBytes));
      }

      if (voiceBytes != null) {
        // Use provided content type or default to wav
        final audioMimeType = voiceContentType ?? 'audio/wav';
        parts.add(InlineDataPart(audioMimeType, voiceBytes));
      }

      // 6) Create AI model for responder assignment
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash-lite',
        systemInstruction: Content.text(
          "You are an emergency dispatch system. "
          "Your job is to assign the best available responder to emergencies. "
          "Return ONLY the responder ID as a number, or 'NONE' if no responder can be assigned. "
          "Do not include any explanation or additional text.",
        ),
        generationConfig: GenerationConfig(
          maxOutputTokens: 50, // Only need a number
          temperature: 0.3, // Lower temperature for more deterministic results
        ),
      );

      // 7) Generate content
      final res = await model.generateContent([Content.multi(parts)]);
      final responseText = (res.text ?? '').trim();

      if (responseText.isEmpty) {
        debugPrint("⚠️ AI returned empty response for responder assignment");
        return;
      }

      // 8) Parse responder ID from response
      final responderIdStr = responseText.replaceAll(RegExp(r'[^\d]'), '');
      if (responderIdStr.isEmpty || responderIdStr.toLowerCase() == 'none') {
        debugPrint("⚠️ AI could not assign a responder");
        return;
      }

      final responderId = int.tryParse(responderIdStr);
      if (responderId == null) {
        debugPrint("⚠️ Could not parse responder ID from: $responseText");
        return;
      }

      // 9) Verify responder exists and is available
      final responderExists = respondersList.any(
        (r) => (r as Map<String, dynamic>)['id'] == responderId,
      );

      if (!responderExists) {
        debugPrint("⚠️ Responder ID $responderId not found in available responders");
        return;
      }

      // 10) Update emergency with assigned responder
      await _supabase
          .from('emergencies')
          .update({
            'responder_id': responderId,
            'status': 'responder_assigned',
          })
          .eq('id', emergencyId);

      debugPrint("✅ Responder $responderId assigned to emergency $emergencyId");
    } catch (e) {
      debugPrint("❌ Responder assignment failed: $e");
      // Don't throw - assignment failure shouldn't break the emergency creation
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180.0);
  }

  String _guessImageContentType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }

  String _guessAudioContentType(String ext) {
    switch (ext) {
      case 'wav':
        return 'audio/wav';
      case 'mp3':
        return 'audio/mpeg';
      case 'aac':
        return 'audio/aac';
      case 'm4a':
      default:
        // Many servers treat m4a as mp4 container
        return 'audio/mp4';
    }
  }
}
