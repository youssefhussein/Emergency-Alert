import 'emergency_history_item.dart';

enum HistoryFilter { all, open, assigned, responding, resolved }
enum HistorySort { newestFirst, oldestFirst }

class EmergencyHistoryState {
  final bool loading;
  final String? error;
  final List<EmergencyHistoryItem> items;
  final HistoryFilter filter;
  final HistorySort sort;

  const EmergencyHistoryState({
    this.loading = false,
    this.error,
    this.items = const [],
    this.filter = HistoryFilter.all,
    this.sort = HistorySort.newestFirst,
  });

  EmergencyHistoryState copyWith({
    bool? loading,
    String? error,
    List<EmergencyHistoryItem>? items,
    HistoryFilter? filter,
    HistorySort? sort,
  }) {
    return EmergencyHistoryState(
      loading: loading ?? this.loading,
      error: error,
      items: items ?? this.items,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }
}
