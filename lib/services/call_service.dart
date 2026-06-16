import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/api_exception.dart';
import '../data/dto.dart';
import '../data/repositories.dart';

/// Manages a single active call: starts it on the backend (which signs a LiveKit
/// token), connects to the media room, and tears everything down on end.
///
/// Media is best-effort — if the LiveKit host is unreachable the call screen
/// still works as signaling-only so the UX never hard-fails.
class CallService {
  CallService._();
  static final CallService instance = CallService._();

  Room? _room;
  CallData? _active;
  CallData? get active => _active;
  Room? get room => _room;

  bool get isInCall => _active != null;

  /// Starts an outgoing call and connects media. Returns the CallData on success,
  /// or a human-readable [error] (e.g. "User is busy right now", "User is offline").
  Future<({CallData? call, String? error})> startOutgoing({
    required String calleeId,
    required bool video,
  }) async {
    if (_active != null) {
      return (call: null, error: 'You are already in a call.');
    }
    try {
      final call = await Repos.calls.start(calleeId: calleeId, video: video);
      _active = call;
      await _connectMedia(call, video: video);
      return (call: call, error: null);
    } on ApiException catch (e) {
      return (call: null, error: e.message);
    } catch (_) {
      return (call: null, error: 'Could not start the call.');
    }
  }

  /// Connects media for an already-negotiated call (e.g. an accepted incoming).
  Future<void> connect(CallData call, {required bool video}) async {
    _active = call;
    await _connectMedia(call, video: video);
  }

  Future<void> _connectMedia(CallData call, {required bool video}) async {
    debugPrint('[CallService] _connectMedia url=${call.mediaServerUrl} token=${call.mediaToken.isNotEmpty ? "present" : "EMPTY"}');
    if (call.mediaServerUrl.isEmpty || call.mediaToken.isEmpty) {
      debugPrint('[CallService] _connectMedia aborted: url or token empty');
      return;
    }
    try {
      final statuses = await [Permission.microphone, if (video) Permission.camera].request();
      debugPrint('[CallService] permissions: $statuses');
      final room = Room();
      await room.connect(call.mediaServerUrl, call.mediaToken);
      debugPrint('[CallService] LiveKit connected, localParticipant=${room.localParticipant?.identity}');
      await room.localParticipant?.setMicrophoneEnabled(true);
      debugPrint('[CallService] mic enabled');
      if (video) await room.localParticipant?.setCameraEnabled(true);
      _room = room;
    } catch (e, st) {
      debugPrint('[CallService] _connectMedia error: $e\n$st');
      _room = null;
    }
  }

  Future<void> setMicEnabled(bool enabled) async {
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(enabled);
    } catch (_) {}
  }

  Future<void> setCameraEnabled(bool enabled) async {
    try {
      await _room?.localParticipant?.setCameraEnabled(enabled);
    } catch (_) {}
  }

  /// Cancels an outgoing call before the callee answers.
  Future<void> cancel() async {
    final id = _active?.id;
    await _teardown();
    if (id != null) {
      try {
        await Repos.calls.cancel(id);
      } catch (_) {}
    }
  }

  /// Ends the call on the backend and disconnects media.
  Future<void> end() async {
    final id = _active?.id;
    await _teardown();
    if (id != null) {
      try {
        await Repos.calls.end(id);
      } catch (_) {}
    }
  }

  Future<void> decline(String callId) async {
    await _teardown();
    try {
      await Repos.calls.decline(callId);
    } catch (_) {}
  }

  Future<void> _teardown() async {
    final lp = _room?.localParticipant;
    if (lp != null) {
      for (final pub in lp.audioTrackPublications) {
        try { await pub.track?.stop(); } catch (_) {}
      }
      for (final pub in lp.videoTrackPublications) {
        try { await pub.track?.stop(); } catch (_) {}
      }
    }
    try { await _room?.disconnect(); } catch (_) {}
    _room = null;
    _active = null;
  }
}
