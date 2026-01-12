import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/contact.dart';
import '../../../services/contact_permissions_service.dart';
import '../../../services/contacts_service.dart';
import 'contacts_state.dart';

class ContactsNotifier extends StateNotifier<ContactsState> {
  final ContactsService _contacts;
  final ContactPermissionsService _perms;
  final SupabaseClient _supabase;

  ContactsNotifier({
    required ContactsService contacts,
    required ContactPermissionsService perms,
    required SupabaseClient supabase,
  }) : _contacts = contacts,
       _perms = perms,
       _supabase = supabase,
       super(const ContactsState());

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await _contacts.getContactsForCurrentUser();
      state = state.copyWith(loading: false, items: _applySort(data, state));
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void toggleFavorite(int id) {
    final fav = {...state.favorites};
    fav.contains(id) ? fav.remove(id) : fav.add(id);

    state = state.copyWith(
      favorites: fav,
      items: _applySort(state.items, state.copyWith(favorites: fav)),
    );
  }

  void setSort(ContactsSort sort) {
    state = state.copyWith(
      sort: sort,
      items: _applySort(state.items, state.copyWith(sort: sort)),
    );
  }

  Future<Contact?> deleteContact(int id) async {
    final idx = state.items.indexWhere((c) => c.id == id);
    if (idx == -1) return null;

    final removed = state.items[idx];

    // Optimistic UI
    final updated = [...state.items]..removeAt(idx);
    state = state.copyWith(items: updated);

    try {
      await _contacts.deleteContact(id);
      return removed;
    } catch (e) {
      // Rollback
      final rollback = [...state.items]..insert(idx, removed);
      state = state.copyWith(items: rollback, error: e.toString());
      return null;
    }
  }

  /// Creates a contact row in `contacts`.
  /// If the email belongs to an existing profile, the service links contact_user_id.
  /// Then we auto-create default permission row in `contact_permissions`.
  Future<void> addContact(Contact contact) async {
    state = state.copyWith(loading: true, error: null);

    try {
      final created = await _contacts.createContact(contact);

      final ownerId = _supabase.auth.currentUser?.id;
      final viewerId = created.contactUserId;

      if (ownerId != null && viewerId != null) {
        // Default privacy: status is OK, medical/location off until user explicitly enables.
        await _perms.upsertPermissions(
          ownerId: ownerId,
          viewerId: viewerId,
          canViewStatus: true,
          canViewMedical: false,
          canViewLocation: false,
          canViewBasicProfile: true,
          canViewEmergencyInfo: false,
        );
      }

      await load();
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  /// For "UNDO" we re-create the contact row (new id) then reload.
  Future<void> undoDelete(Contact removed) async {
    try {
      await addContact(removed.copyWith(id: null));
    } catch (_) {
      // addContact already sets error
    }
  }

  List<Contact> _applySort(List<Contact> list, ContactsState s) {
    final items = [...list];

    switch (s.sort) {
      case ContactsSort.nameAsc:
        items.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;

      case ContactsSort.favoritesFirst:
        items.sort((a, b) {
          final aId = a.id ?? -1;
          final bId = b.id ?? -1;

          final aFav = s.favorites.contains(aId) ? 1 : 0;
          final bFav = s.favorites.contains(bId) ? 1 : 0;

          final favDiff = bFav - aFav;
          if (favDiff != 0) return favDiff;

          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
    }

    return items;
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, ContactsState>(
  (ref) {
    final supabase = Supabase.instance.client;

    return ContactsNotifier(
      supabase: supabase,
      contacts: ContactsService(supabase),
      perms: ContactPermissionsService(supabase),
    )..load();
  },
);
