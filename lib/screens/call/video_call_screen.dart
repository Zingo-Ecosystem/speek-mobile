import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' hide Session;

import '../../data/dto.dart';
import '../../models/models.dart';
import '../../realtime/realtime_service.dart';
import '../../services/call_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/common.dart';
import 'call_controls.dart';
import 'call_ended_screen.dart';

class VideoCallScreen extends StatefulWidget {
  final SpeekUser user;

  /// Callee tomonidan beriladi — screen ichida LiveKit ga ulanadi.
  final CallData? callData;

  const VideoCallScreen({super.key, required this.user, this.callData});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  StreamSubscription? _stateSub;
  EventsListener<RoomEvent>? _roomListener;
  Timer? _ticker;
  String? _callId;

  bool _connected = false;
  bool _handedOff = false;
  DateTime? _connectedAt;
  Duration _elapsed = Duration.zero;

  bool _muted = false;
  bool _cameraOn = true;
  bool _cameraFront = true;
  bool _remoteCameraOff = false;

  VideoTrack? _remoteVideoTrack;
  VideoTrack? _localVideoTrack;

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
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _connectedAt != null) {
        setState(() => _elapsed = DateTime.now().difference(_connectedAt!));
      }
    });

    _callId = widget.callData?.id ?? CallService.instance.active?.id;

    final cd = widget.callData;
    if (cd != null) {
      // Callee: screen ochiladi (connecting holatda), keyin LiveKit ga ulaniladi.
      CallService.instance.connect(cd, video: true).then((_) {
        debugPrint('[VideoCallScreen] callee connect done, room=${CallService.instance.room != null}');
        if (mounted) {
          _forceSpeaker();
          _setupRoomListener();
        }
      });
    } else {
      // Caller: room allaqachon tayyor.
      _setupRoomListener();
    }

    _stateSub = RealtimeService.instance.onCallState.listen((c) {
      debugPrint('[VideoCallScreen] callState status=${c.status}');
      if (!mounted) return;
      if ((_callId == null || c.id.isEmpty || c.id == _callId) && c.status >= 3) _navigateToEnded();
    });
  }

  void _setupRoomListener() {
    final room = CallService.instance.room;
    debugPrint('[VideoCallScreen] _setupRoomListener room=${room != null}');

    if (room == null) {
      _onPeerConnected();
      return;
    }

    _refreshLocalTrack(room);

    // Allaqachon subscribed tracklar bormi?
    bool alreadyConnected = false;
    for (final p in room.remoteParticipants.values) {
      for (final pub in p.videoTrackPublications) {
        if (pub.subscribed && pub.track != null) {
          _remoteVideoTrack = pub.track as VideoTrack?;
          _remoteCameraOff = pub.muted;
          alreadyConnected = true;
        }
      }
      if (!alreadyConnected) {
        alreadyConnected =
            p.audioTrackPublications.any((t) => t.subscribed);
      }
    }
    if (alreadyConnected) _onPeerConnected();

    // Listener har doim o'rnatiladi — future event lar uchun
    _roomListener = room.createListener()
      ..on<LocalTrackPublishedEvent>((_) {
        debugPrint('[VideoCallScreen] LocalTrackPublishedEvent');
        if (mounted) _refreshLocalTrack(room);
      })
      ..on<TrackSubscribedEvent>((e) {
        debugPrint('[VideoCallScreen] TrackSubscribedEvent kind=${e.track.kind}');
        if (e.track.kind == TrackType.VIDEO) {
          if (mounted) {
            setState(() {
              _remoteVideoTrack = e.track as VideoTrack;
              _remoteCameraOff = false;
            });
          }
          _onPeerConnected();
        } else if (e.track.kind == TrackType.AUDIO) {
          _onPeerConnected();
          _forceSpeaker();
        }
      })
      ..on<TrackUnsubscribedEvent>((e) {
        if (e.track.kind == TrackType.VIDEO && mounted) {
          setState(() => _remoteVideoTrack = null);
        }
      })
      ..on<TrackMutedEvent>((e) {
        if (e.participant is RemoteParticipant &&
            e.publication.source == TrackSource.camera &&
            mounted) {
          debugPrint('[VideoCallScreen] remote camera muted');
          setState(() => _remoteCameraOff = true);
        }
      })
      ..on<TrackUnmutedEvent>((e) {
        if (e.participant is RemoteParticipant &&
            e.publication.source == TrackSource.camera &&
            mounted) {
          debugPrint('[VideoCallScreen] remote camera unmuted');
          setState(() => _remoteCameraOff = false);
        }
      })
      ..on<ParticipantDisconnectedEvent>((_) {
        debugPrint('[VideoCallScreen] ParticipantDisconnectedEvent');
        _navigateToEnded();
      })
      ..on<RoomDisconnectedEvent>((_) {
        debugPrint('[VideoCallScreen] RoomDisconnectedEvent');
        _navigateToEnded();
      });
  }

  void _refreshLocalTrack(Room room) {
    for (final pub in room.localParticipant?.videoTrackPublications ?? []) {
      final track = pub.track;
      if (track != null && track is VideoTrack && mounted) {
        setState(() => _localVideoTrack = track);
        return;
      }
    }
  }

  void _onPeerConnected() {
    if (!mounted || _connected) return;
    debugPrint('[VideoCallScreen] _onPeerConnected');
    _forceSpeaker();
    setState(() {
      _connected = true;
      _connectedAt = DateTime.now();
    });
  }

  // LiveKit audio pipeline initializes asynchronously and can reset speaker
  // routing. Call setSpeakerphoneOn immediately and repeat after a short delay.
  void _forceSpeaker() {
    Hardware.instance.setSpeakerphoneOn(true);
    Future.delayed(const Duration(milliseconds: 500), () {
      Hardware.instance.setSpeakerphoneOn(true);
    });
  }

  void _navigateToEnded() {
    if (!mounted || _handedOff) return;
    _handedOff = true;
    _stateSub?.cancel();
    _roomListener?.dispose();
    CallService.instance.end();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => CallEndedScreen(user: widget.user, duration: _elapsed, callId: _callId)),
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

  Future<void> _toggleCamera() async {
    final newState = !_cameraOn;
    setState(() {
      _cameraOn = newState;
      if (!newState) _localVideoTrack = null;
    });
    await CallService.instance.setCameraEnabled(newState);
    if (mounted && newState) {
      final room = CallService.instance.room;
      if (room != null) _refreshLocalTrack(room);
    }
  }

  Future<void> _switchCamera() async {
    final wantFront = !_cameraFront;
    try {
      final room = CallService.instance.room;
      if (room == null) return;

      final devices = await Hardware.instance.videoInputs();
      debugPrint('[VideoCallScreen] cameras: ${devices.map((d) => d.label).toList()}');
      if (devices.length < 2) return;

      // Label bo'yicha front/back kamerani topamiz
      MediaDevice? target;
      for (final d in devices) {
        final lbl = d.label.toLowerCase();
        if (wantFront && lbl.contains('front')) { target = d; break; }
        if (!wantFront && (lbl.contains('back') || lbl.contains('environment'))) {
          target = d;
          break;
        }
      }

      // Label ishlamasa — hozirgi devicedan boshqa birinchi kamerani olamiz
      if (target == null) {
        final currentId = room.selectedVideoInputDeviceId;
        target = devices.firstWhere(
          (d) => d.deviceId != currentId,
          orElse: () => devices[(devices.indexWhere((d) => d.deviceId == currentId) + 1) % devices.length],
        );
      }

      setState(() => _cameraFront = wantFront);
      await room.setVideoInputDevice(target);
      debugPrint('[VideoCallScreen] switched to ${target.label}');
      if (mounted) _refreshLocalTrack(room);
    } catch (e) {
      debugPrint('[VideoCallScreen] switchCamera error: $e');
      if (mounted) setState(() => _cameraFront = wantFront); // revert
    }
  }

  void _end(BuildContext context) {
    _handedOff = true;
    _stateSub?.cancel();
    _roomListener?.dispose();
    CallService.instance.end();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => CallEndedScreen(user: widget.user, duration: _elapsed, callId: _callId)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Remote video / fallback photo
          if (_remoteVideoTrack != null && !_remoteCameraOff)
            VideoTrackRenderer(_remoteVideoTrack!)
          else
            Image.network(
              user.photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: Colors.black),
            ),

          // Gradient overlay
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.78),
                ],
                stops: const [0, 0.28, 1],
              ),
            ),
          ),

          // Connecting overlay — peer kutilmoqda
          AnimatedOpacity(
            opacity: _connected ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 400),
            child: IgnorePointer(
              ignoring: _connected,
              child: Container(
                color: Colors.black.withValues(alpha: 0.60),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.brand500.withValues(alpha: 0.5),
                              width: 3),
                          boxShadow: [
                            BoxShadow(
                                color:
                                    AppColors.brand500.withValues(alpha: 0.4),
                                blurRadius: 36)
                          ],
                        ),
                        child: Avatar(user.photoUrl, size: 110, name: user.name),
                      ),
                      const SizedBox(height: 20),
                      Text('${user.name} ${user.flag}',
                          style: AppText.displayMd),
                      const SizedBox(height: 14),
                      const _ConnectingDots(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top bar: timer (voice call bilan bir xil margin va markazda)
          Positioned(
            top: topPad + 24,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _connected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('📹 Video · $_clock',
                      style: AppText.caption.copyWith(color: Colors.white)),
                ),
              ),
            ),
          ),

          // Self PiP (local camera)
          Positioned(
            top: topPad + 50,
            right: 16,
            child: Container(
              width: 92,
              height: 124,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _cameraOn && _localVideoTrack != null
                    ? VideoTrackRenderer(_localVideoTrack!)
                    : Container(
                        color: Colors.grey[900],
                        child: Icon(
                          _cameraOn
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          color: Colors.white38,
                          size: 30,
                        ),
                      ),
              ),
            ),
          ),

          // User info above controls
          Positioned(
            bottom: bottomPad + 112,
            left: 18,
            right: 18,
            child: AnimatedOpacity(
              opacity: _connected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Text(
                '${user.name} · ${user.flag} ${user.city}',
                style: AppText.label,
              ),
            ),
          ),

          // Controls
          Positioned(
            bottom: bottomPad + 40,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _connected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: IgnorePointer(
                ignoring: !_connected,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CallControl(
                        icon: _muted
                            ? Icons.mic_off_rounded
                            : Icons.mic_rounded,
                        small: true,
                        variant: _muted
                            ? CallControlVariant.active
                            : CallControlVariant.normal,
                        onTap: _toggleMute),
                    const SizedBox(width: 16),
                    CallControl(
                        icon: _cameraOn
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        small: true,
                        variant: _cameraOn
                            ? CallControlVariant.normal
                            : CallControlVariant.active,
                        onTap: _toggleCamera),
                    const SizedBox(width: 16),
                    CallControl(
                        icon: Icons.cameraswitch_rounded,
                        small: true,
                        onTap: _switchCamera),
                    const SizedBox(width: 16),
                    CallControl(
                        icon: Icons.close,
                        small: true,
                        variant: CallControlVariant.end,
                        onTap: () => _end(context)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectingDots extends StatefulWidget {
  const _ConnectingDots();
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
        AppText.body.copyWith(color: Colors.white.withValues(alpha: 0.7));
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final dots = ['', '.', '..', '...'][(_c.value * 4).floor() % 4];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Connecting', style: style),
            SizedBox(width: 24, child: Text(dots, style: style)),
          ],
        );
      },
    );
  }
}
