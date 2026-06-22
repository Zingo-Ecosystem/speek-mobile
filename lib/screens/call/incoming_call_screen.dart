import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' hide Session;

import '../../core/session.dart';
import '../../models/models.dart';
import '../../realtime/realtime_service.dart';
import '../../services/call_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';
import 'call_controls.dart';
import 'video_call_screen.dart';
import 'voice_call_screen.dart';

/// Caller tomonidan ko'rinadigan ekran.
/// Faza 1 — voice/video tanlash.
/// Faza 2 — call boshlangach, callee accept qilguncha "Chaqirilmoqda…" ko'rinadi.
/// Callee accept qilgach → VoiceCallScreen/VideoCallScreen.
class IncomingCallScreen extends StatefulWidget {
  final SpeekUser user;
  const IncomingCallScreen({super.key, required this.user});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  bool _calling = false;
  bool _busy = false;
  bool? _video;
  bool _handedOff = false;
  StreamSubscription? _stateSub;
  EventsListener<RoomEvent>? _roomListener;
  Timer? _noAnswerTimer;

  @override
  void dispose() {
    _stateSub?.cancel();
    _roomListener?.dispose();
    _noAnswerTimer?.cancel();
    if (!_handedOff) CallService.instance.cancel();
    super.dispose();
  }

  Future<void> _startCall({required bool video}) async {
    if (_busy) return;
    if (!Session.instance.isAuthenticated) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = true;
      _calling = true;
      _video = video;
    });

    // startOutgoing dan OLDIN o'rnatiladi — tez rad etish/bekor qilish eventlari
    // startOutgoing kutilayotganda ham kelishi mumkin, broadcast streamda bufferlanmaydi.
    _stateSub = RealtimeService.instance.onCallState.listen((c) {
      debugPrint('[IncomingCallScreen] callState id=${c.id} status=${c.status} handedOff=$_handedOff');
      if (!mounted || _handedOff) return;
      if (c.status >= 3) {
        _stateSub?.cancel();
        _noAnswerTimer?.cancel();
        _roomListener?.dispose();
        CallService.instance.end();
        Navigator.of(context).pop();
        showSnack(context, 'Call ended', type: SnackType.info);
      }
    });

    final res = await CallService.instance.startOutgoing(
      calleeId: widget.user.id,
      video: video,
    );

    if (!mounted) return;

    if (res.error != null) {
      _stateSub?.cancel();
      showSnack(context, res.error!, type: SnackType.error);
      setState(() {
        _busy = false;
        _calling = false;
      });
      return;
    }

    setState(() => _busy = false);
    // 60 soniya ichida javob bo'lmasa avtomatik bekor qilish
    _noAnswerTimer = Timer(const Duration(seconds: 60), () {
      if (mounted && !_handedOff) _cancel();
    });

    // LiveKit: callee room ga qo'shilganda navigate qilamiz
    final room = CallService.instance.room;
    if (room != null) {
      final hasTrack = room.remoteParticipants.values
          .any((p) => p.audioTrackPublications.any((t) => t.subscribed));
      if (hasTrack) {
        _onPeerJoined(video);
      } else {
        _roomListener = room.createListener()
          ..on<TrackSubscribedEvent>((_) => _onPeerJoined(video));
      }
    }
  }

  void _onPeerJoined(bool video) {
    if (!mounted) return;
    _stateSub?.cancel();
    _roomListener?.dispose();
    _handedOff = true;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => video
          ? VideoCallScreen(user: widget.user)
          : VoiceCallScreen(user: widget.user),
    ));
  }

  Future<void> _cancel() async {
    _stateSub?.cancel();
    await CallService.instance.cancel();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradDeep),
        child: Stack(
          children: [
            const BrandGlow(opacity: 0.4),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _PulseAvatar(url: u.photoUrl),
                  const SizedBox(height: 22),
                  Text('${u.name} ${u.flag}', style: AppText.displayMd),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _calling
                        ? Text(
                            key: const ValueKey('ringing'),
                            'Calling…',
                            style: AppText.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.8)),
                          )
                        : Text(
                            key: const ValueKey('start'),
                            'Choose call type',
                            style: AppText.body.copyWith(
                                color: Colors.white.withValues(alpha: 0.8)),
                          ),
                  ),
                  const SizedBox(height: 14),
                  if (_calling && _video != null)
                    Pill(
                      _video! ? '📹 Video call' : '🎙 Voice call',
                      bg: Colors.white.withValues(alpha: 0.15),
                      fg: Colors.white,
                      border: Colors.white.withValues(alpha: 0.25),
                    ),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: _calling
                        ? CallControl(
                            icon: Icons.call_end_rounded,
                            label: 'Cancel',
                            variant: CallControlVariant.end,
                            onTap: _cancel,
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              CallControl(
                                icon: Icons.close,
                                label: 'Back',
                                variant: CallControlVariant.end,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              CallControl(
                                icon: Icons.videocam_rounded,
                                label: 'Video',
                                onTap: _busy
                                    ? null
                                    : () => _startCall(video: true),
                              ),
                              CallControl(
                                icon: Icons.call,
                                label: 'Voice',
                                variant: CallControlVariant.accept,
                                onTap: _busy
                                    ? null
                                    : () => _startCall(video: false),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseAvatar extends StatefulWidget {
  final String url;
  const _PulseAvatar({required this.url});
  @override
  State<_PulseAvatar> createState() => _PulseAvatarState();
}

class _PulseAvatarState extends State<_PulseAvatar>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final t = _c.value;
              return Container(
                width: 128 + t * 60,
                height: 128 + t * 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: (1 - t) * 0.3)),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 3),
            ),
            child: Avatar(widget.url, size: 128),
          ),
        ],
      ),
    );
  }
}
