import 'package:supabase_flutter/supabase_flutter.dart';
import 'emergency_service.dart';

class EmergencyRequestService {
  final SupabaseClient _supabase;

  EmergencyRequestService(this._supabase);

  Future<void> sendRequest({
    required EmergencyService service,
    String? userId,
    String? description, // stored in emergencies.notes
    String? phone, // stored in emergencies.phone
    double? latitude, // stored in emergencies.location_lat
    double? longitude, // stored in emergencies.location_lng
  }) async {
    final effectiveUserId = userId ?? _supabase.auth.currentUser?.id;
    if (effectiveUserId == null) {
      throw Exception("No authenticated user. Login required.");
    }

    await _supabase.from('emergencies').insert({
      'user_id': effectiveUserId,
      'type': service.type.name, // ambulance/police/fire/hospital
      'status': 'open',
      'phone': phone,
      'notes': description,
      'location_lat': latitude,
      'location_lng': longitude,
      // created_at uses DB default
    });
  }
}
