import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/responder.dart';

class ResponderService {
  final SupabaseClient _supabase;
  ResponderService(this._supabase);

  /// Demo responder login: user enters a responder UUID that exists in `responders.uuid`.
  Future<Responder?> getResponderByUuid(String uuid) async {
    final code = uuid.trim();
    if (code.isEmpty) return null;

    final row = await _supabase
        .from('responders')
        .select('id, uuid, type, institute_name, address_name, status')
        .eq('uuid', code)
        .maybeSingle();

    if (row == null) return null;
    return Responder.fromJson(row);
  }

  Future<List<Map<String, dynamic>>> getAssignedEmergencies({
    required int responderId,
    int limit = 100,
  }) async {
    final rows = await _supabase
        .from('emergencies')
        .select('*')
        .eq('responder_id', responderId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List).cast<Map<String, dynamic>>();
  }

  Future<void> acceptEmergency({required int emergencyId, required int responderId}) async {
    // Minimal-safe update (columns exist in your schema)
    await _supabase.from('emergencies').update({
      'status': 'accepted',
      'responder_id': responderId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', emergencyId);

    // Optional columns (if you added them)
    try {
      await _supabase.from('emergencies').update({
        'accepted_at': DateTime.now().toIso8601String(),
      }).eq('id', emergencyId);
    } catch (_) {}
  }

  Future<void> rejectEmergency({
    required int emergencyId,
    required int responderId,
    required String reason,
  }) async {
    await _supabase.from('emergencies').update({
      'status': 'rejected',
      'responder_id': responderId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', emergencyId);

    try {
      await _supabase.from('emergencies').update({
        'rejected_at': DateTime.now().toIso8601String(),
        'rejected_reason': reason,
      }).eq('id', emergencyId);
    } catch (_) {}
  }

  Future<void> setInProgress({required int emergencyId}) async {
    await _supabase.from('emergencies').update({
      'status': 'in_progress',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', emergencyId);
  }

  Future<void> setSolved({required int emergencyId}) async {
    await _supabase.from('emergencies').update({
      'status': 'solved',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', emergencyId);

    try {
      await _supabase.from('emergencies').update({
        'solved_at': DateTime.now().toIso8601String(),
      }).eq('id', emergencyId);
    } catch (_) {}
  }
}
