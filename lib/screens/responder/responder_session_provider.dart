import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/responder.dart';
import '../../services/responder_service.dart';
import '../../services/responder_session_service.dart';

class ResponderAuthState {
  final bool loading;
  final String? error;
  final Responder? responder;

  const ResponderAuthState({
    this.loading = false,
    this.error,
    this.responder,
  });

  ResponderAuthState copyWith({
    bool? loading,
    String? error,
    Responder? responder,
  }) {
    return ResponderAuthState(
      loading: loading ?? this.loading,
      error: error,
      responder: responder ?? this.responder,
    );
  }
}

class ResponderAuthNotifier extends StateNotifier<ResponderAuthState> {
  final ResponderService _service;
  final ResponderSessionService _session;

  ResponderAuthNotifier(this._service, this._session)
      : super(const ResponderAuthState());

  Future<void> restore() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final saved = await _session.load();
      if (saved == null) {
        state = state.copyWith(loading: false, responder: null);
        return;
      }
      final responder = await _service.getResponderByUuid(saved.responderUuid);
      state = ResponderAuthState(loading: false, responder: responder);
    } catch (e) {
      state = ResponderAuthState(loading: false, error: e.toString());
    }
  }

  Future<bool> loginWithUuid(String uuid) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final responder = await _service.getResponderByUuid(uuid);
      if (responder == null) {
        state = const ResponderAuthState(loading: false, error: 'Invalid responder code.');
        return false;
      }
      await _session.save(responderId: responder.id, responderUuid: responder.uuid);
      state = ResponderAuthState(loading: false, responder: responder);
      return true;
    } catch (e) {
      state = ResponderAuthState(loading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _session.clear();
    state = const ResponderAuthState(responder: null);
  }
}

final responderServiceProvider = Provider<ResponderService>((ref) {
  return ResponderService(Supabase.instance.client);
});

final responderSessionServiceProvider = Provider<ResponderSessionService>((ref) {
  return ResponderSessionService();
});

final responderAuthProvider = StateNotifierProvider<ResponderAuthNotifier, ResponderAuthState>((ref) {
  return ResponderAuthNotifier(
    ref.read(responderServiceProvider),
    ref.read(responderSessionServiceProvider),
  );
});
