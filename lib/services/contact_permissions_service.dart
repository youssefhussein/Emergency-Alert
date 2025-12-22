import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact_permissions.dart';

class ContactPermissionsService {
  final SupabaseClient _supabase;

  ContactPermissionsService(this._supabase);

  Future<ContactPermissions?> getPermissions({
    required String ownerId,
    required String contactUserId,
  }) async {
    final row = await _supabase
        .from('contact_permissions')
        .select('*')
        .eq('owner_id', ownerId)
        .eq('contact_user_id', contactUserId)
        .maybeSingle();

    if (row == null) return null;
    return ContactPermissions.fromJson(row);
  }

  Future<void> setPermissions({
    required String ownerId,
    required String contactUserId,
    required bool status,
    required bool medical,
    required bool location,
  }) async {
    await _supabase.from('contact_permissions').upsert({
      'owner_id': ownerId,
      'contact_user_id': contactUserId,
      'can_view_status': status,
      'can_view_medical': medical,
      'can_view_location': location,
    });
  }
}
