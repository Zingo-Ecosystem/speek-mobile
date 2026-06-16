import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../config/app_config.dart';
import '../core/session.dart';
import '../data/dto.dart';
import '../models/models.dart';

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

  final _messages = StreamController<Message>.broadcast();
  final _incomingCalls = StreamController<CallData>.broadcast();
  final _callStates = StreamController<CallData>.broadcast();
  final _notifications = StreamController<AppNotification>.broadcast();
  final _typing = StreamController<TypingEvent>.broadcast();

  Stream<Message> get onMessage => _messages.stream;
  Stream<CallData> get onIncomingCall => _incomingCalls.stream;
  Stream<CallData> get onCallState => _callStates.stream;
  Stream<AppNotification> get onNotification => _notifications.stream;
  Stream<TypingEvent> get onTyping => _typing.stream;

  bool get isConnected => _hub?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    if (_starting || isConnected) return;
    if (!Session.instance.isAuthenticated) return;
    _starting = true;
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

      hub.on('message', (a) => _emit(a, _messages, Message.fromJson));
      hub.on('incomingCall', (a) => _emit(a, _incomingCalls, CallData.fromJson));
      hub.on('callState', (a) => _emit(a, _callStates, CallData.fromJson));
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

      _hub = hub;
      await hub.start();
    } catch (_) {
      // Realtime is best-effort; REST still works without it.
    } finally {
      _starting = false;
    }
  }

  /// Relay a typing indicator to a peer.
  Future<void> sendTyping(String peerId, bool isTyping) async {
    if (!isConnected) return;
    try {
      await _hub!.invoke('Typing', args: [peerId, isTyping]);
    } catch (_) {}
  }

  Future<void> disconnect() async {
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
