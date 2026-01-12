import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_db_service.dart';

final localDbProvider = Provider<LocalDbService>((ref) {
  final db = LocalDbService();
  ref.onDispose(() => db.close());
  return db;
});
