// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'emergency_service.dart';
// import 'dart:typed_data';

// class EmergencyRequestService {
//   final SupabaseClient _supabase;

//   EmergencyRequestService(this._supabase);

//   // Future<void> sendRequest({
//   //   required EmergencyService service,
//   //   String? userId,
//   //   String? description, // stored in emergencies.notes
//   //   String? phone, // stored in emergencies.phone
//   //   double? latitude, // stored in emergencies.location_lat
//   //   double? longitude, // stored in emergencies.location_lng
//   // }) async {
//   //   final effectiveUserId = userId ?? _supabase.auth.currentUser?.id;
//   //   if (effectiveUserId == null) {
//   //     throw Exception("No authenticated user. Login required.");
//   //   }

//   //   await _supabase.from('emergencies').insert({
//   //     'user_id': effectiveUserId,
//   //     'type': service.type.name, // ambulance/police/fire/hospital
//   //     'status': 'open',
//   //     'phone': phone,
//   //     'notes': description,
//   //     'location_lat': latitude,
//   //     'location_lng': longitude,
//   //     // created_at uses DB default
//   //   });
//   // }

//   // add: import 'dart:typed_data';

//   Future<int> sendRequest({
//     required EmergencyService service,
//     String? userId,
//     String? notes,
//     String? phone,

//     // new
//     bool shareLocation = true,
//     bool notifyContacts = false,
//     String? locationDetails,

//     double? latitude,
//     double? longitude,

//     Uint8List? photoBytes,
//     String? photoExt, // 'jpg','png'...
//     String? photoContentType, // 'image/jpeg'...

//     Uint8List? voiceBytes,
//     String? voiceExt, // 'm4a','wav'...
//     String? voiceContentType, // 'audio/mp4'...
//     int? voiceDurationSec,
//   }) async {
//     final uid = userId ?? _supabase.auth.currentUser?.id;
//     if (uid == null) throw Exception("No authenticated user");

//     // 1) insert and get id
//     final inserted = await _supabase
//         .from('emergencies')
//         .insert({
//           'user_id': uid,
//           'type': service.type.name,
//           'status': 'open',
//           'phone': phone,
//           'notes': notes,
//           'share_location': shareLocation,
//           'notify_contacts': notifyContacts,
//           'location_details': locationDetails,
//           'location_lat': shareLocation ? latitude : null,
//           'location_lng': shareLocation ? longitude : null,
//         })
//         .select('id')
//         .single();

//     final emergencyId = inserted['id'] as int;

//     String? photoPath;
//     String? voicePath;

//     // 2) upload photo
//     if (photoBytes != null) {
//       final ext = (photoExt ?? 'jpg').replaceAll('.', '');
//       photoPath = '$uid/emergencies/$emergencyId/photo.$ext';

//       await _supabase.storage
//           .from('emergency-media')
//           .uploadBinary(
//             photoPath,
//             photoBytes,
//             fileOptions: FileOptions(
//               contentType: photoContentType ?? 'image/jpeg',
//               upsert: true,
//             ),
//           );
//     }

//     // 3) upload voice note
//     if (voiceBytes != null) {
//       final ext = (voiceExt ?? 'm4a').replaceAll('.', '');
//       voicePath = '$uid/emergencies/$emergencyId/voice.$ext';

//       await _supabase.storage
//           .from('emergency-media')
//           .uploadBinary(
//             voicePath,
//             voiceBytes,
//             fileOptions: FileOptions(
//               contentType: voiceContentType ?? 'audio/mp4',
//               upsert: true,
//             ),
//           );
//     }

//     // 4) update emergency row with storage paths
//     final update = <String, dynamic>{};
//     if (photoPath != null) update['photo_url'] = photoPath;
//     if (voicePath != null) update['voice_note_url'] = voicePath;
//     if (voiceDurationSec != null)
//       update['voice_note_duration_sec'] = voiceDurationSec;

//     if (update.isNotEmpty) {
//       await _supabase.from('emergencies').update(update).eq('id', emergencyId);
//     }

//     return emergencyId;
//   }
// }
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'emergency_service.dart';

class EmergencyRequestService {
  final SupabaseClient _supabase;

  EmergencyRequestService(this._supabase);

  /// Creates an emergency row first, then uploads optional media to Storage,
  /// then updates the row with the Storage object paths.
  ///
  /// NOTE:
  /// - `photo_url` and `voice_note_url` should store the *storage path* (object key),
  ///   not a signed URL (signed URLs expire).
  Future<int> sendRequest({
    required EmergencyService service,
    String? userId,

    /// Stored in `emergencies.notes`
    String? description,

    /// Stored in `emergencies.phone`
    String? phone,

    /// Stored in `emergencies.location_lat/lng` if shareLocation is true
    double? latitude,
    double? longitude,

    /// Stored in `emergencies.share_location`
    bool shareLocation = true,

    /// Stored in `emergencies.notify_contacts`
    bool notifyContacts = false,

    /// Stored in `emergencies.location_details`
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
          'type': service.type.name, // ambulance/police/fire/hospital
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

    // if (voiceBytes != null) {
    //   final ext = _cleanExt(voiceExt, fallback: 'm4a');
    //   voicePath = '$effectiveUserId/emergencies/$emergencyId/voice.$ext';

    //   await _supabase.storage
    //       .from('emergency-media')
    //       .uploadBinary(
    //         voicePath,
    //         voiceBytes,
    //         fileOptions: FileOptions(
    //           contentType: voiceContentType ?? _guessAudioContentType(ext),
    //           upsert: true,
    //         ),
    //       );
    // }

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
    // if (voicePath != null) update['voice_note_url'] = voicePath;
    // if (voiceDurationSec != null) {
    //   update['voice_note_duration_sec'] = voiceDurationSec;
    // }
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
