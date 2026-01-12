import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/dispatch_service.dart';

final dispatchServiceProvider = Provider<DispatchService>((ref) {
  return DispatchService(Supabase.instance.client);
});

class DispatchState {
  final bool loading;
  final String? error;
  final int? lastAssignedCount;
  final int? lastRequeuedCount;

  const DispatchState({
    this.loading = false,
    this.error,
    this.lastAssignedCount,
    this.lastRequeuedCount,
  });
}

class DispatchNotifier extends StateNotifier<DispatchState> {
  final DispatchService _svc;

  DispatchNotifier(this._svc) : super(const DispatchState());

  Future<void> runDispatch({int maxAssign = 200}) async {
    state = const DispatchState(loading: true);
    try {
      final n = await _svc.assignPendingBatch(maxAssign: maxAssign);
      state = DispatchState(loading: false, lastAssignedCount: n);
    } catch (e) {
      state = DispatchState(loading: false, error: e.toString());
    }
  }

  Future<void> requeueExpired({int expireSeconds = 60}) async {
    state = const DispatchState(loading: true);
    try {
      final n = await _svc.requeueExpiredAssignments(
        expireSeconds: expireSeconds,
      );
      state = DispatchState(loading: false, lastRequeuedCount: n);
    } catch (e) {
      state = DispatchState(loading: false, error: e.toString());
    }
  }
}

final dispatchProvider = StateNotifierProvider<DispatchNotifier, DispatchState>(
  (ref) {
    return DispatchNotifier(ref.read(dispatchServiceProvider));
  },
);
