import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';

class ProfileService {
  final SupabaseClient _supabase;

  ProfileService(this._supabase);

  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', user!.id)
        .maybeSingle();

    if (data == null) return null;

    return UserProfile.fromJson(data);
  }

  Future<UserProfile> upsertCurrentUserProfile(UserProfile profile) async {
    final user = _supabase.auth.currentUser;

    final payload = profile.toJson()
      ..['id'] = user!.id
      ..['email'] = user.email;
    final data = await _supabase
        .from('profiles')
        .upsert(payload)
        .select()
        .single();

    return UserProfile.fromJson(data);
  }

  Future<void> deleteCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final res = await _supabase.from('profiles').delete().eq('id', user.id);

    print('Delete result: $res');
  }

  Future<UserProfile?> getProfileByUserId(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return UserProfile.fromJson(data);
  }

  Future<UserProfile?> getProfile(String userId) async {
    final row = await _supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    return UserProfile.fromJson(row);
  }
}
