import 'dart:typed_data';
import 'dart:math' as math;

import 'package:emergency_alert/services/estimated_time_arrival_service.dart';
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
    // _assignResponderAI(
    //   emergencyId: emergencyId,
    //   emergencyType: service.type.name,
    //   description: description,
    //   locationDetails: locationDetails,
    //   latitude: latitude,
    //   longitude: longitude,
    //   photoBytes: photoBytes,
    //   photoContentType: photoContentType,
    //   voiceBytes: voiceBytes,
    //   voiceContentType: voiceContentType,
    // );



    //assign a responder or notify them idk
    // final etas = await EstimatedTimeArrivalService().fetchResponderETAs(
    //   emergencyLat: latitude!,
    //   emergencyLng: longitude!,
    //   emergencyType: service.type.name.toLowerCase(),
    // );
    
    // if (etas.isNotEmpty) {
    //   final firstResponder = etas.first;
    //   debugPrint("This is the first responder in the listtt $firstResponder");
    //   await _supabase.from('emergencies').update({
    //     'responder_id': firstResponder.responderId,
    //   }).eq('id', emergencyId);
    // }

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


  




    
  
}
