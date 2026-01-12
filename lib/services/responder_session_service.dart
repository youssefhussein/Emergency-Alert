import 'package:shared_preferences/shared_preferences.dart';

class ResponderSession {
  final int responderId;
  final String responderUuid;

  const ResponderSession({
    required this.responderId,
    required this.responderUuid,
  });
}

/// Stores a responder "demo session" locally.
///
/// Responders in your schema are NOT auth users, so we keep a local session using
/// SharedPreferences.
class ResponderSessionService {
  static const _kResponderId = 'responder_id';
  static const _kResponderUuid = 'responder_uuid';

  Future<ResponderSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_kResponderId);
    final uuid = prefs.getString(_kResponderUuid);
    if (id == null || uuid == null || uuid.trim().isEmpty) return null;
    return ResponderSession(responderId: id, responderUuid: uuid);
  }

  Future<void> save({required int responderId, required String responderUuid}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kResponderId, responderId);
    await prefs.setString(_kResponderUuid, responderUuid);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kResponderId);
    await prefs.remove(_kResponderUuid);
  }
}
