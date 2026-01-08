import '../../models/contact.dart';

enum ContactsSort { nameAsc, favoritesFirst }

class ContactsState {
  final bool loading;
  final String? error;
  final List<Contact> items;
  final Set<String> favorites;
  final ContactsSort sort;

  const ContactsState({
    this.loading = false,
    this.error,
    this.items = const [],
    this.favorites = const {},
    this.sort = ContactsSort.favoritesFirst,
  });

  ContactsState copyWith({
    bool? loading,
    String? error,
    List<Contact>? items,
    Set<String>? favorites,
    ContactsSort? sort,
  }) {
    return ContactsState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      favorites: favorites ?? this.favorites,
      sort: sort ?? this.sort,
    );
  }
}
