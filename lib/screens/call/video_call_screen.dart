import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../realtime/realtime_service.dart';
import '../../services/call_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import 'call_controls.dart';
import 'call_ended_screen.dart';

class VideoCallScreen extends StatefulWidget {
  final SpeekUser user;
  const VideoCallScreen({super.key, required this.user});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  StreamSubscription? _stateSub;
  Timer? _ticker;
  final _start = DateTime.now();
  Duration _elapsed = Duration.zero;

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
      if (mounted) setState(() => _elapsed = DateTime.now().difference(_start));
    });
    _stateSub = RealtimeService.instance.onCallState.listen((c) {
      if (c.status >= 3 && mounted) {
        _stateSub?.cancel();
        CallService.instance.end();
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => CallEndedScreen(user: widget.user)));
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(user.photoUrl, fit: BoxFit.cover),
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

          // Top bar
          Positioned(
            top: topPad + 8,
            left: 18,
            right: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('LIVE · $_clock',
                          style: AppText.caption.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.cameraswitch_rounded,
                      color: Colors.white, size: 18),
                ),
              ],
            ),
          ),

          // Self PiP
          Positioned(
            top: topPad + 50,
            right: 16,
            child: Container(
              width: 92,
              height: 124,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=400&q=80',
                    fit: BoxFit.cover),
              ),
            ),
          ),

          // Caption
          Positioned(
            bottom: 150,
            left: 18,
            right: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${user.name} · ${user.flag} ${user.city}',
                    style: AppText.label),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14)),
                  child: Text('“So what part of the city do you live in?”',
                      style: AppText.body),
                ),
              ],
            ),
          ),

          // Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CallControl(icon: Icons.mic_rounded, small: true),
                const SizedBox(width: 16),
                const CallControl(icon: Icons.photo_camera_rounded, small: true),
                const SizedBox(width: 16),
                CallControl(
                    icon: Icons.close,
                    variant: CallControlVariant.end,
                    onTap: () {
                      CallService.instance.end();
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (_) => CallEndedScreen(user: user)));
                    }),
                const SizedBox(width: 16),
                const CallControl(
                    icon: Icons.cameraswitch_rounded, small: true),
                const SizedBox(width: 16),
                const CallControl(
                    icon: Icons.chat_bubble_outline_rounded, small: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
