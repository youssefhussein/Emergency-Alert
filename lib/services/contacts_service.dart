import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/contact.dart';

class ContactsService {
  final SupabaseClient _supabase;

  ContactsService(this._supabase);

  String? get _uid => _supabase.auth.currentUser?.id;

  // Get my contacts (owner_id = current user)
  Future<List<Contact>> getContactsForCurrentUser() async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('Not logged in');
    }

    final rows = await _supabase
        .from('contacts')
        .select('*')
        .eq('owner_id', uid)
        .order('created_at');

    return (rows as List<dynamic>)
        .map((r) => Contact.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // People who added ME as a contact
  // (contact_user_id = current user)
  Future<List<Contact>> getPeopleWhoAddedMe() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not logged in');

    final rows = await _supabase
        .from('contacts')
        .select('*')
        .eq('contact_user_id', uid)
        .order('created_at');

    return (rows as List<dynamic>)
        .map((r) => Contact.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> respondToIncomingRequest({
    required String contactId,
    required bool accept,
  }) async {
    final intId = int.tryParse(contactId) ?? contactId;

    await _supabase
        .from('contacts')
        .update({'status': accept ? 'accepted' : 'rejected'})
        .eq('id', intId);
  }

  // Create new contact
  Future<Contact> createContact(Contact contact) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not logged in');

    final inserted = await _supabase
        .from('contacts')
        .insert(contact.toInsertMap(uid))
        .select()
        .single();

    return Contact.fromJson(inserted);
  }

  // Update existing contact
  Future<void> updateContact(Contact contact) async {
    // contacts.id is BIGINT in DB → send as int
    final intId = int.tryParse(contact.id) ?? contact.id;

    await _supabase
        .from('contacts')
        .update(contact.toUpdateMap())
        .eq('id', intId);
  }

  // Delete contact by id
  Future<void> deleteContact(String id) async {
    final intId = int.tryParse(id) ?? id;

    await _supabase.from('contacts').delete().eq('id', intId);
  }
}
