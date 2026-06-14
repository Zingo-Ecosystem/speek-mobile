import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/common.dart';
import 'call_controls.dart';
import 'video_call_screen.dart';
import 'voice_call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  final SpeekUser user;
  const IncomingCallScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
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
                  _PulseAvatar(url: user.photoUrl),
                  const SizedBox(height: 22),
                  Text('${user.name} ${user.flag}', style: AppText.displayMd),
                  const SizedBox(height: 6),
                  Text('Starting Speek call…',
                      style: AppText.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 14),
                  Pill('🎙 Voice call',
                      bg: Colors.white.withValues(alpha: 0.15),
                      fg: Colors.white,
                      border: Colors.white.withValues(alpha: 0.25)),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CallControl(
                          icon: Icons.close,
                          label: 'Decline',
                          variant: CallControlVariant.end,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        CallControl(
                          icon: Icons.videocam_rounded,
                          label: 'Video',
                          onTap: () => _go(context, video: true),
                        ),
                        CallControl(
                          icon: Icons.call,
                          label: 'Accept',
                          variant: CallControlVariant.accept,
                          onTap: () => _go(context, video: false),
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

  void _go(BuildContext context, {required bool video}) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => video
          ? VideoCallScreen(user: user)
          : VoiceCallScreen(user: user),
    ));
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
            builder: (_, __) {
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
