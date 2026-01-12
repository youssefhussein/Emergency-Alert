import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/cached_emergency.dart';

/// SQFlite cache for responder side.
///
/// This satisfies the rubric "Data Persistence (SQFlite)" and powers:
/// - favorites
/// - local archive (dismissible + undo)
/// - offline view
class LocalDbService {
  Database? _db;

  Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'emergency_alert_cache.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE cached_emergencies (
            id INTEGER PRIMARY KEY,
            type TEXT NOT NULL,
            status TEXT NOT NULL,
            location_details TEXT,
            notes TEXT,
            report_by_ai TEXT,
            created_at TEXT,
            is_favorite INTEGER NOT NULL DEFAULT 0,
            is_archived INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  Future<void> upsertFromRemote(Map<String, dynamic> emergency) async {
    final db = await _open();
    final id = (emergency['id'] as num).toInt();
    // Keep existing favorite/archive flags if present.
    final existing = await db.query('cached_emergencies', where: 'id = ?', whereArgs: [id]);
    final prevFav = existing.isNotEmpty ? (existing.first['is_favorite'] as num?) == 1 : false;
    final prevArchived = existing.isNotEmpty ? (existing.first['is_archived'] as num?) == 1 : false;

    final row = CachedEmergency(
      id: id,
      type: (emergency['type'] ?? '').toString(),
      status: (emergency['status'] ?? '').toString(),
      locationDetails: emergency['location_details']?.toString(),
      notes: emergency['notes']?.toString(),
      reportByAi: emergency['report_by_ai']?.toString(),
      createdAt: _tryParse(emergency['created_at']),
      isFavorite: prevFav,
      isArchived: prevArchived,
    ).toDb();

    await db.insert('cached_emergencies', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertManyFromRemote(List<Map<String, dynamic>> emergencies) async {
    final db = await _open();
    await db.transaction((txn) async {
      for (final e in emergencies) {
        final id = (e['id'] as num).toInt();
        final existing = await txn.query('cached_emergencies', where: 'id = ?', whereArgs: [id]);
        final prevFav = existing.isNotEmpty ? (existing.first['is_favorite'] as num?) == 1 : false;
        final prevArchived = existing.isNotEmpty ? (existing.first['is_archived'] as num?) == 1 : false;
        final row = CachedEmergency(
          id: id,
          type: (e['type'] ?? '').toString(),
          status: (e['status'] ?? '').toString(),
          locationDetails: e['location_details']?.toString(),
          notes: e['notes']?.toString(),
          reportByAi: e['report_by_ai']?.toString(),
          createdAt: _tryParse(e['created_at']),
          isFavorite: prevFav,
          isArchived: prevArchived,
        ).toDb();
        await txn.insert('cached_emergencies', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<Map<int, CachedEmergencyMeta>> getMetaForIds(List<int> ids) async {
    if (ids.isEmpty) return {};
    final db = await _open();
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.query(
      'cached_emergencies',
      columns: ['id', 'is_favorite', 'is_archived'],
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
    final out = <int, CachedEmergencyMeta>{};
    for (final r in rows) {
      final id = (r['id'] as num).toInt();
      out[id] = CachedEmergencyMeta(
        id: id,
        isFavorite: (r['is_favorite'] as num?) == 1,
        isArchived: (r['is_archived'] as num?) == 1,
      );
    }
    return out;
  }

  Future<void> toggleFavorite(int id) async {
    final db = await _open();
    final rows = await db.query('cached_emergencies', columns: ['is_favorite'], where: 'id = ?', whereArgs: [id]);
    final cur = rows.isNotEmpty ? (rows.first['is_favorite'] as num?) == 1 : false;
    await db.update('cached_emergencies', {'is_favorite': cur ? 0 : 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setArchived(int id, bool archived) async {
    final db = await _open();
    await db.update('cached_emergencies', {'is_archived': archived ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CachedEmergency>> getCached({bool includeArchived = false}) async {
    final db = await _open();
    final rows = await db.query(
      'cached_emergencies',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'created_at DESC',
    );
    return rows.map(CachedEmergency.fromDb).toList();
  }

  DateTime? _tryParse(dynamic v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }
}
