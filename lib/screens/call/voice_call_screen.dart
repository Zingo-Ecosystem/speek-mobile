import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../realtime/realtime_service.dart';
import '../../services/call_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/common.dart';
import 'call_controls.dart';
import 'call_ended_screen.dart';
import 'video_call_screen.dart';

class VoiceCallScreen extends StatefulWidget {
  final SpeekUser user;
  const VoiceCallScreen({super.key, required this.user});

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
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
    // Leave automatically if the other party declines/ends/cancels.
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
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text('🎙 Voice · $_clock',
                        style: AppText.caption.copyWith(color: Colors.white)),
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
                  const _Waveform(),
                  const SizedBox(height: 18),
                  Pill('🎙 Live captions: “…sí, me encanta viajar”'),
                  const Spacer(flex: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CallControl(
                          icon: Icons.mic_off_rounded, label: 'Mute', small: true),
                      const SizedBox(width: 22),
                      const CallControl(
                          icon: Icons.volume_up_rounded,
                          label: 'Speaker',
                          small: true),
                      const SizedBox(width: 22),
                      CallControl(
                          icon: Icons.videocam_rounded,
                          label: 'Video',
                          small: true,
                          variant: CallControlVariant.active,
                          onTap: () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (_) => VideoCallScreen(user: u)))),
                      const SizedBox(width: 22),
                      const CallControl(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Chat',
                          small: true),
                    ],
                  ),
                  const SizedBox(height: 22),
                  CallControl(
                    icon: Icons.close,
                    label: 'End',
                    variant: CallControlVariant.end,
                    onTap: () => _end(context),
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

  void _end(BuildContext context) {
    CallService.instance.end();
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => CallEndedScreen(user: widget.user)));
  }
}

class _Waveform extends StatefulWidget {
  const _Waveform();
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
        builder: (_, __) {
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
