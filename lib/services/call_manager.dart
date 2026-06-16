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
    // Already ringing or already in a call → auto-decline so the caller gets a
    // clean "busy" instead of a second ring stacking up.
    if (nav == null || _ringing || CallService.instance.isInCall) {
      Repos.calls.decline(call.id).catchError((_) {});
      return;
    }
    _ringing = true;

    // Best-effort: enrich the ring screen with the caller's profile.
    SpeekUser? caller;
    try {
      caller = await Repos.profile.byId(call.callerId);
    } catch (_) {}

    await nav.push(MaterialPageRoute(
      builder: (_) => IncomingRingScreen(call: call, caller: caller),
    ));
    _ringing = false;
  }
}
