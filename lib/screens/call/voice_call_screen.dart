import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../data/dto.dart';
import '../../models/models.dart';
import '../../realtime/realtime_service.dart';
import '../../services/call_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/common.dart';
import 'call_controls.dart';
import 'call_ended_screen.dart';

class VoiceCallScreen extends StatefulWidget {
  final SpeekUser user;
  /// Callee tomonidan beriladi — screen ichida LiveKit ga ulanadi.
  final CallData? callData;
  const VoiceCallScreen({super.key, required this.user, this.callData});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  StreamSubscription? _stateSub;
  EventsListener<RoomEvent>? _roomListener;
  Timer? _ticker;
  String? _callId;
  bool _connected = false;
  bool _handedOff = false;
  DateTime? _connectedAt;
  Duration _elapsed = Duration.zero;
  bool _muted = false;
  bool _speakerOn = false;

  String get _clock {
    final s = _elapsed.inSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = sec.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  void initState() {
    super.initState();
    Hardware.instance.setSpeakerphoneOn(false);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _connectedAt != null) {
        setState(() => _elapsed = DateTime.now().difference(_connectedAt!));
      }
    });

    _callId = widget.callData?.id ?? CallService.instance.active?.id;

    final cd = widget.callData;
    if (cd != null) {
      // Callee: screen ochiladi (connecting), keyin LiveKit ga ulaniladi
      CallService.instance.connect(cd, video: cd.isVideo).then((_) {
        debugPrint('[VoiceCallScreen] callee connect done, room=${CallService.instance.room != null}');
        if (mounted) _setupRoomListener();
      });
    } else {
      // Caller: room allaqachon tayyor
      _setupRoomListener();
    }

    _stateSub = RealtimeService.instance.onCallState.listen((c) {
      debugPrint('[VoiceCallScreen] callState status=${c.status}');
      if (!mounted) return;
      if ((_callId == null || c.id.isEmpty || c.id == _callId) && c.status >= 3) {
        _navigateToEnded();
      }
    });
  }

  void _setupRoomListener() {
    final room = CallService.instance.room;
    debugPrint('[VoiceCallScreen] _setupRoomListener room=${room != null}');

    if (room == null) {
      _onPeerConnected();
      return;
    }

    final hasSubscribed = room.remoteParticipants.values.any(
      (p) => p.audioTrackPublications.any((t) => t.subscribed),
    );

    debugPrint('[VoiceCallScreen] hasSubscribed=$hasSubscribed');

    if (hasSubscribed) _onPeerConnected();

    _roomListener = room.createListener()
      ..on<TrackSubscribedEvent>((e) {
        debugPrint('[VoiceCallScreen] TrackSubscribedEvent: ${e.track.kind}');
        if (e.track.kind == TrackType.AUDIO) _onPeerConnected();
      })
      ..on<ParticipantDisconnectedEvent>((_) {
        debugPrint('[VoiceCallScreen] ParticipantDisconnectedEvent');
        _navigateToEnded();
      })
      ..on<RoomDisconnectedEvent>((_) {
        debugPrint('[VoiceCallScreen] RoomDisconnectedEvent');
        _navigateToEnded();
      });
  }

  void _onPeerConnected() {
    if (!mounted || _connected) return;
    debugPrint('[VoiceCallScreen] _onPeerConnected');
    setState(() {
      _connected = true;
      _connectedAt = DateTime.now();
    });
  }

  void _navigateToEnded() {
    if (!mounted || _handedOff) return;
    _handedOff = true;
    _stateSub?.cancel();
    _roomListener?.dispose();
    CallService.instance.end();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => CallEndedScreen(user: widget.user, duration: _elapsed)),
      (route) => route.isFirst,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stateSub?.cancel();
    _roomListener?.dispose();
    if (!_handedOff) CallService.instance.end();
    super.dispose();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    CallService.instance.setMicEnabled(!_muted);
  }

  void _toggleSpeaker() {
    setState(() => _speakerOn = !_speakerOn);
    Hardware.instance.setSpeakerphoneOn(_speakerOn);
  }

  void _end(BuildContext context) {
    _handedOff = true;
    _stateSub?.cancel();
    _roomListener?.dispose();
    CallService.instance.end();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => CallEndedScreen(user: widget.user, duration: _elapsed)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final sub = u.role == SpeakerRole.learner
        ? 'Learner · ${u.city} · ${u.level}'
        : 'Native · ${u.city}';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.1,
            colors: [Color(0xFF241F4D), Color(0xFF0B0B12)],
          ),
        ),
        child: Stack(
          children: [
            const BrandGlow(),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  AnimatedOpacity(
                    opacity: _connected ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('🎙 Voice · $_clock',
                          style: AppText.caption
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                  const Spacer(flex: 2),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.brand500.withValues(alpha: 0.5),
                          width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.brand500.withValues(alpha: 0.5),
                            blurRadius: 40)
                      ],
                    ),
                    child: Avatar(u.photoUrl, size: 150),
                  ),
                  const SizedBox(height: 20),
                  Text('${u.name} ${u.flag}', style: AppText.displayMd),
                  const SizedBox(height: 4),
                  Text(sub, style: AppText.smMuted),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _connected
                        ? _Waveform(key: const ValueKey('wave'), muted: _muted)
                        : const _ConnectingDots(key: ValueKey('dots')),
                  ),
                  const Spacer(flex: 3),
                  AnimatedOpacity(
                    opacity: _connected ? 1 : 0,
                    duration: const Duration(milliseconds: 400),
                    child: IgnorePointer(
                      ignoring: !_connected,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CallControl(
                                  icon: _muted
                                      ? Icons.mic_off_rounded
                                      : Icons.mic_rounded,
                                  label: 'Mute',
                                  small: true,
                                  variant: _muted
                                      ? CallControlVariant.active
                                      : CallControlVariant.normal,
                                  onTap: _toggleMute),
                              const SizedBox(width: 22),
                              CallControl(
                                  icon: Icons.volume_up_rounded,
                                  label: 'Speaker',
                                  small: true,
                                  variant: _speakerOn
                                      ? CallControlVariant.active
                                      : CallControlVariant.normal,
                                  onTap: _toggleSpeaker),
                            ],
                          ),
                          const SizedBox(height: 22),
                          CallControl(
                            icon: Icons.call_end_rounded,
                            label: 'End',
                            variant: CallControlVariant.end,
                            onTap: () => _end(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectingDots extends StatefulWidget {
  const _ConnectingDots({super.key});
  @override
  State<_ConnectingDots> createState() => _ConnectingDotsState();
}

class _ConnectingDotsState extends State<_ConnectingDots>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style =
        AppText.body.copyWith(color: Colors.white.withValues(alpha: 0.6));
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final step = (_c.value * 4).floor() % 4;
        final dots = ['', '.', '..', '...'][step];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ulanmoqda', style: style),
            SizedBox(width: 24, child: Text(dots, style: style)),
          ],
        );
      },
    );
  }
}

class _Waveform extends StatefulWidget {
  final bool muted;
  const _Waveform({super.key, required this.muted});
  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();
  final _rand = Random();
  late final _bases = List.generate(16, (_) => 8 + _rand.nextDouble() * 26);

  @override
  void didUpdateWidget(_Waveform old) {
    super.didUpdateWidget(old);
    if (widget.muted != old.muted) {
      widget.muted ? _c.stop() : _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < _bases.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Container(
                    width: 4,
                    height: _bases[i] *
                        (0.5 + 0.5 * (1 + sin(_c.value * 2 * pi + i)) / 2),
                    decoration: BoxDecoration(
                        color: AppColors.brand400,
                        borderRadius: BorderRadius.circular(3)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
