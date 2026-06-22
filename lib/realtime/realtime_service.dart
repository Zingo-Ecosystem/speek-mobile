import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../config/app_config.dart';
import '../core/session.dart';
import '../data/dto.dart';
import '../models/models.dart';
import '../services/notification_service.dart';

/// Wraps the SignalR connection to `/hubs/realtime`.
///
/// Server → client events (see SpeekHub): message, incomingCall, callState,
/// notification, typing, presence. Each is surfaced as a broadcast stream so
/// any screen can listen without owning the connection.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  HubConnection? _hub;
  bool _starting = false;
  Timer? _retryTimer;

  /// Set to the peer ID of the currently open ConversationScreen.
  /// Null when no conversation is open.
  String? activePeerId;

  final _peerNames = <String, String>{};

  /// Call from ConversationScreen.initState so notifications know the peer's name.
  void registerPeer(String id, String name) => _peerNames[id] = name;

  final _messages = StreamController<Message>.broadcast();
  final _incomingCalls = StreamController<CallData>.broadcast();
  final _callStates = StreamController<CallData>.broadcast();
  final _notifications = StreamController<AppNotification>.broadcast();
  final _typing = StreamController<TypingEvent>.broadcast();
  final _invites = StreamController<InviteEvent>.broadcast();

  Stream<Message> get onMessage => _messages.stream;
  Stream<CallData> get onIncomingCall => _incomingCalls.stream;
  Stream<CallData> get onCallState => _callStates.stream;
  Stream<AppNotification> get onNotification => _notifications.stream;
  Stream<TypingEvent> get onTyping => _typing.stream;
  Stream<InviteEvent> get onInvite => _invites.stream;

  bool get isConnected => _hub?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    if (_starting || isConnected) return;
    if (!Session.instance.isAuthenticated) return;
    _starting = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    try {
      final hub = HubConnectionBuilder()
          .withUrl(
            AppConfig.realtimeHubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async => Session.instance.accessToken ?? '',
            ),
          )
          .withAutomaticReconnect()
          .build();

      hub.on('message', (a) {
        debugPrint('[RealtimeService] message raw: $a');
        final map = _first(a);
        if (map != null && map['outgoing'] != true) {
          final senderId =
              (map['senderId'] ?? map['from'] ?? '').toString();
          if (senderId.isNotEmpty && senderId != activePeerId) {
            final name = _peerNames[senderId] ?? 'Speek';
            final text = (map['text'] ?? '').toString();
            NotificationService.instance.showMessage(
              senderName: name,
              text: text.isEmpty ? '📎 Media' : text,
            );
          }
        }
        _emit(a, _messages, Message.fromJson);
      });
      hub.on('invite', (a) {
        debugPrint('[RealtimeService] invite raw: $a');
        final map = _first(a);
        if (map == null) return;
        try {
          final from = SpeekUser.fromJson(
              (map['from'] as Map).cast<String, dynamic>());
          final convId = (map['conversationId'] ?? '').toString();
          final msg = map['message'];
          final text = msg is Map ? (msg['text'] ?? '').toString() : '';
          NotificationService.instance.showMessage(
            senderName: from.name,
            text: text.isEmpty ? '👋 Wants to practice speaking' : text,
          );
          _invites.add(InviteEvent(
            conversationId: convId,
            from: from,
            mode: map['mode'] is int ? map['mode'] as int : null,
          ));
        } catch (e) {
          debugPrint('[RealtimeService] invite parse failed: $e');
        }
      });
      hub.on('incomingCall', (a) {
        debugPrint('[RealtimeService] incomingCall raw: $a');
        _emit(a, _incomingCalls, CallData.fromJson);
      });
      hub.on('callState', (a) {
        debugPrint('[RealtimeService] callState raw: $a');
        _emit(a, _callStates, CallData.fromJson);
      });
      hub.on('notification', (a) => _emit(a, _notifications, AppNotification.fromJson));
      hub.on('typing', (a) {
        final m = _first(a);
        if (m != null) {
          _typing.add(TypingEvent(
            from: '${m['from']}',
            isTyping: m['isTyping'] == true,
          ));
        }
      });

      hub.onclose(({Exception? error}) {
        debugPrint('[RealtimeService] connection closed: $error');
        // withAutomaticReconnect handles transient drops; schedule a manual
        // retry here only for clean closes (error == null) or fatal failures.
        _scheduleRetry();
      });
      hub.onreconnecting(({Exception? error}) =>
          debugPrint('[RealtimeService] reconnecting: $error'));
      hub.onreconnected(({String? connectionId}) =>
          debugPrint('[RealtimeService] reconnected id=$connectionId'));

      _hub = hub;
      await hub.start();
      debugPrint('[RealtimeService] connected to ${AppConfig.realtimeHubUrl}');
    } catch (e) {
      debugPrint('[RealtimeService] connect failed: $e');
      _hub = null;
      _scheduleRetry();
    } finally {
      _starting = false;
    }
  }

  /// Schedules a reconnect attempt with exponential-ish back-off (5 s → 15 s).
  int _retryCount = 0;
  void _scheduleRetry() {
    if (!Session.instance.isAuthenticated) return;
    _retryTimer?.cancel();
    final delay = _retryCount < 3
        ? const Duration(seconds: 5)
        : const Duration(seconds: 15);
    _retryCount++;
    _retryTimer = Timer(delay, () async {
      if (Session.instance.isAuthenticated) {
        await connect();
        if (isConnected) _retryCount = 0;
      }
    });
  }

  /// Relay a typing indicator to a peer.
  Future<void> sendTyping(String peerId, bool isTyping) async {
    if (!isConnected) return;
    try {
      await _hub!.invoke('Typing', args: [peerId, isTyping]);
    } catch (_) {}
  }

  Future<void> disconnect() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = 0;
    try {
      await _hub?.stop();
    } catch (_) {}
    _hub = null;
  }

  Map<String, dynamic>? _first(List<Object?>? args) {
    if (args == null || args.isEmpty) return null;
    final a = args.first;
    if (a is Map) return a.cast<String, dynamic>();
    return null;
  }

  void _emit<T>(List<Object?>? args, StreamController<T> ctrl,
      T Function(Map<String, dynamic>) parse) {
    final m = _first(args);
    if (m != null) {
      try {
        ctrl.add(parse(m));
      } catch (_) {}
    }
  }
}

class TypingEvent {
  final String from;
  final bool isTyping;
  TypingEvent({required this.from, required this.isTyping});
}

/// Fired when another user sends a "practice with me" invite from the map.
class InviteEvent {
  final String conversationId;
  final SpeekUser from;

  /// Suggested medium: null = chat, 0 = voice, 1 = video.
  final int? mode;
  InviteEvent({required this.conversationId, required this.from, this.mode});
}
