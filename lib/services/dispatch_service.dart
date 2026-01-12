import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls Supabase SQL RPC functions that implement dispatch + assignment.
///
/// Create these functions in Supabase SQL editor:
/// - assign_pending_batch(max_assign int) returns int
/// - requeue_expired_assignments(expire_seconds int) returns int
class DispatchService {
  final SupabaseClient _db;
  DispatchService(this._db);

  Future<int> assignPendingBatch({int maxAssign = 200}) async {
    final res = await _db.rpc('assign_pending_batch', params: {'max_assign': maxAssign});
    return (res as num).toInt();
  }

  Future<int> requeueExpiredAssignments({int expireSeconds = 60}) async {
    final res = await _db.rpc(
      'requeue_expired_assignments',
      params: {'expire_seconds': expireSeconds},
    );
    return (res as num).toInt();
  }
}
