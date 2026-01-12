import '../models/contact_permissions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContactPermissionsService {
  final SupabaseClient _supabase;

  ContactPermissionsService(this._supabase);

  Future<ContactPermissions?> getPermissions({
    required String ownerId,
    required String viewerId,
  }) async {
    // Some projects enforce uniqueness on (owner_id, viewer_id) while others use
    // (owner_id, contact_user_id). We support both to avoid duplicate-key errors.

    // 1) Prefer the explicit owner->viewer mapping.
    final row1 = await _supabase
        .from('contact_permissions')
        .select('*')
        .eq('owner_id', ownerId)
        .eq('viewer_id', viewerId)
        .maybeSingle();

    if (row1 != null) {
      return ContactPermissions.fromJson(row1 as Map<String, dynamic>);
    }

    // 2) Fallback: owner->contact_user mapping (common unique constraint).
    final row2 = await _supabase
        .from('contact_permissions')
        .select('*')
        .eq('owner_id', ownerId)
        .eq('contact_user_id', viewerId)
        .maybeSingle();

    if (row2 == null) return null;
    return ContactPermissions.fromJson(row2 as Map<String, dynamic>);
  }

  /// Creates or updates permissions (UPSERT) for the owner->viewer relationship.
  Future<void> upsertPermissions({
    required String ownerId,
    required String viewerId,
    bool canViewStatus = true,
    bool canViewMedical = false,
    bool canViewLocation = false,
    bool canViewBasicProfile = true,
    bool canViewEmergencyInfo = false,
  }) async {
    final payload = <String, dynamic>{
      'owner_id': ownerId,
      'viewer_id': viewerId,
      'contact_user_id': viewerId, // keep consistent with your schema
      'can_view_status': canViewStatus,
      'can_view_medical': canViewMedical,
      'can_view_location': canViewLocation,
      'can_view_basic_profile': canViewBasicProfile,
      'can_view_emergency_info': canViewEmergencyInfo,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // IMPORTANT:
    // Your DB has a UNIQUE constraint ("contact_permissions_owner_contact_unique").
    // If RLS blocks SELECT, we can't reliably "check then insert".
    // So we use PostgREST UPSERT with an explicit onConflict target.
    // We try the most common unique target first: (owner_id, contact_user_id).
    try {
      await _supabase
          .from('contact_permissions')
          .upsert(payload, onConflict: 'owner_id,contact_user_id');
    } catch (_) {
      // Fallback for projects that use (owner_id, viewer_id) instead.
      await _supabase
          .from('contact_permissions')
          .upsert(payload, onConflict: 'owner_id,viewer_id');
    }
  }
}
