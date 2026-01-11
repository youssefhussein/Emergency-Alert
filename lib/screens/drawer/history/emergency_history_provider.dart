import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'emergency_history_item.dart';
import 'emergency_history_state.dart';

class EmergencyHistoryNotifier extends StateNotifier<EmergencyHistoryState> {
  final SupabaseClient _supabase;

  EmergencyHistoryNotifier(this._supabase)
    : super(const EmergencyHistoryState());

  Future<void> load() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      state = state.copyWith(
        error: 'Not signed in.',
        loading: false,
        items: [],
      );
      return;
    }

    state = state.copyWith(loading: true, error: null);

    try {
      final rows = await _supabase
          .from('emergencies')
          .select('id,type,status,created_at,notes')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final items = (rows as List)
          .map((e) => EmergencyHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList();

      state = state.copyWith(loading: false, items: items);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: 'Failed to load history: $e',
      );
    }
  }

  void setFilter(HistoryFilter f) {
    state = state.copyWith(filter: f);
  }

  void setSort(HistorySort s) {
    state = state.copyWith(sort: s);
  }

  List<EmergencyHistoryItem> get visibleItems {
    Iterable<EmergencyHistoryItem> out = state.items;
    switch (state.filter) {
      case HistoryFilter.open:
        out = out.where((e) => e.status == 'open' || e.status == 'pending');
        break;
      case HistoryFilter.assigned:
        out = out.where((e) => e.status == 'assigned');
        break;
      case HistoryFilter.responding:
        out = out.where((e) => e.status == 'responding');
        break;
      case HistoryFilter.resolved:
        out = out.where((e) => e.status == 'resolved' || e.status == 'closed');
        break;
      case HistoryFilter.all:
        break;
    }

    final list = out.toList();
    list.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      return state.sort == HistorySort.newestFirst ? -cmp : cmp;
    });
    return list;
  }

  /// Delete from DB. Returns the removed item so UI can offer UNDO.
  Future<EmergencyHistoryItem?> delete(int id) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final idx = state.items.indexWhere((e) => e.id == id);
    if (idx == -1) return null;
    final removed = state.items[idx];

    // Optimistic UI
    final next = [...state.items]..removeAt(idx);
    state = state.copyWith(items: next);

    try {
      await _supabase
          .from('emergencies')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
      return removed;
    } catch (e) {
      // Rollback
      final rollback = [...state.items]..insert(idx, removed);
      state = state.copyWith(items: rollback, error: 'Delete failed: $e');
      return null;
    }
  }

  /// Best-effort undo: re-inserts the emergency as a new record (new ID).
  Future<void> undoDelete(EmergencyHistoryItem removed) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('emergencies')
          .insert(removed.toInsertJson(userId: userId));
      await load();
    } catch (e) {
      state = state.copyWith(error: 'Undo failed: $e');
    }
  }
}

final emergencyHistoryProvider =
    StateNotifierProvider<EmergencyHistoryNotifier, EmergencyHistoryState>((
      ref,
    ) {
      final notifier = EmergencyHistoryNotifier(Supabase.instance.client);
      Future.microtask(notifier.load);
      return notifier;
    });
