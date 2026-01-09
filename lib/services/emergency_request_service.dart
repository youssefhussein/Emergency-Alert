import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'emergency_service.dart';

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
    if (voiceDurationSec != null)
      update['voice_note_duration_sec'] = voiceDurationSec;

    if (update.isNotEmpty) {
      await _supabase.from('emergencies').update(update).eq('id', emergencyId);
    }

    return emergencyId;
  }

  String _cleanExt(String? ext, {required String fallback}) {
    final e = (ext ?? '').trim().toLowerCase();
    if (e.isEmpty) return fallback;
    return e.startsWith('.') ? e.substring(1) : e;
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
