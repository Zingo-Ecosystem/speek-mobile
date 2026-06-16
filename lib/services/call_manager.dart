import 'dart:async';

import 'package:flutter/material.dart';

import '../data/dto.dart';
import '../data/repositories.dart';
import '../models/models.dart';
import '../realtime/realtime_service.dart';
import '../screens/call/incoming_ring_screen.dart';
import 'call_service.dart';

/// App-wide coordinator that listens for inbound calls over SignalR and rings
/// the user no matter which screen they're on. Owns the global navigator key.
class CallManager {
  CallManager._();
  static final CallManager instance = CallManager._();

  final navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<CallData>? _sub;
  bool _ringing = false;

  void start() {
    _sub ??= RealtimeService.instance.onIncomingCall.listen(_onIncoming);
  }

  Future<void> _onIncoming(CallData call) async {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      debugPrint('[CallManager] nav is null — declining ${call.id}');
      Repos.calls.decline(call.id).catchError((_) {});
      return;
    }
    if (_ringing) {
      debugPrint('[CallManager] already ringing — declining ${call.id}');
      Repos.calls.decline(call.id).catchError((_) {});
      return;
    }
    if (CallService.instance.isInCall) {
      debugPrint('[CallManager] already in call — declining ${call.id}');
      Repos.calls.decline(call.id).catchError((_) {});
      return;
    }

    _ringing = true;
    debugPrint('[CallManager] showing IncomingRingScreen for call ${call.id}');

    SpeekUser? caller;
    try {
      caller = await Repos.profile.byId(call.callerId);
    } catch (_) {}

    try {
      await nav.push(MaterialPageRoute(
        builder: (_) => IncomingRingScreen(call: call, caller: caller),
      ));
    } finally {
      _ringing = false;
    }
  }
}
