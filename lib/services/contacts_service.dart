
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/contact.dart';

class ContactsService {
  final SupabaseClient _supabase;

  ContactsService(this._supabase);

  String? get _uid => _supabase.auth.currentUser?.id;

  /// Lookup a user in `profiles` by email and return their uuid (profiles.id),
  /// or null if not found.
  Future<String?> resolveUserIdByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    final row = await _supabase
        .from('profiles')
        .select('id')
        .eq('email', normalized)
        .maybeSingle();

    if (row == null) return null;
    return row['id'] as String?;
  }

  Future<List<Contact>> getContactsForCurrentUser() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not logged in');

    final rows = await _supabase
        .from('contacts')
        .select('*')
        .eq('owner_id', uid)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((r) => Contact.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<Contact>> getPeopleWhoAddedMe() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not logged in');

    final rows = await _supabase
        .from('contacts')
        .select('*')
        .eq('contact_user_id', uid)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((r) => Contact.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> respondToIncomingRequest({
    required int contactId,
    required bool accept,
  }) async {
    await _supabase
        .from('contacts')
        .update({'status': accept ? 'accepted' : 'rejected'})
        .eq('id', contactId);
  }

  /// Create contact:
  /// - inserts into `contacts`
  /// - if contact_email exists in `profiles`, sets contact_user_id automatically
  Future<Contact> createContact(Contact contact) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not logged in');

    String? resolvedUserId;
    if (contact.email != null && contact.email!.trim().isNotEmpty) {
      resolvedUserId = await resolveUserIdByEmail(contact.email!);
    }

    final inserted = await _supabase
        .from('contacts')
        .insert(
          contact.toInsertMap(
            ownerId: uid,
            resolvedContactUserId: resolvedUserId,
          ),
        )
        .select()
        .single();

    return Contact.fromJson(inserted as Map<String, dynamic>);
  }

  Future<void> updateContact(Contact contact) async {
    final id = contact.id;
    if (id == null) throw Exception('Contact id is missing');

    await _supabase.from('contacts').update(contact.toUpdateMap()).eq('id', id);
  }

  Future<void> deleteContact(int id) async {
    await _supabase.from('contacts').delete().eq('id', id);
  }
}
