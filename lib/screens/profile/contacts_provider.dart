import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/contacts_service.dart';
import '../../models/contact.dart';
import 'contacts_state.dart';

class ContactsNotifier extends StateNotifier<ContactsState> {
  final ContactsService service;

  ContactsNotifier(this.service) : super(const ContactsState());

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final data = await service.getContactsForCurrentUser();
      state = state.copyWith(loading: false, items: _applySort(data, state));
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void toggleFavorite(String id) {
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

  Future<Contact?> deleteContact(String id) async {
    final idx = state.items.indexWhere((c) => c.id == id);
    if (idx == -1) return null;

    final removed = state.items[idx];
    final updated = [...state.items]..removeAt(idx);
    state = state.copyWith(items: updated);

    await service.deleteContact(id);
    return removed;
  }

  Future<void> undoDelete(Contact contact, {int? index}) async {
    final updated = [...state.items];
    if (index != null && index >= 0 && index <= updated.length) {
      updated.insert(index, contact);
    } else {
      updated.insert(0, contact);
    }
    state = state.copyWith(items: _applySort(updated, state));
    // optional: re-insert in DB if you have "addContact" available
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
          final aFav = s.favorites.contains(a.id) ? 1 : 0;
          final bFav = s.favorites.contains(b.id) ? 1 : 0;
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
    return ContactsNotifier(ContactsService(supabase));
  },
);
