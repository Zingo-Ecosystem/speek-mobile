import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/dto.dart';
import '../../data/repositories.dart';
import '../../models/models.dart';
import '../../realtime/realtime_service.dart';
import '../../services/call_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/common.dart';
import 'video_call_screen.dart';
import 'voice_call_screen.dart';

/// Shown to the *callee* when an inbound call rings (driven by the SignalR
/// `incomingCall` event). Accept → joins the LiveKit room; Decline → notifies
/// the caller and closes.
class IncomingRingScreen extends StatefulWidget {
  final CallData call;
  final SpeekUser? caller;
  const IncomingRingScreen({super.key, required this.call, this.caller});

  @override
  State<IncomingRingScreen> createState() => _IncomingRingScreenState();
}

class _IncomingRingScreenState extends State<IncomingRingScreen> {
  bool _busy = false;
  StreamSubscription? _stateSub;
  Timer? _ringTimer;

  @override
  void initState() {
    super.initState();
    _startRinging();
    final myCallId = widget.call.id;
    if (myCallId.isEmpty) return; // guard against closing on a missing id
    _stateSub = RealtimeService.instance.onCallState.listen((c) {
      debugPrint('[IncomingRingScreen] callState id=${c.id} status=${c.status} myId=$myCallId');
      if (c.id == myCallId && c.status >= 3 && mounted) {
        _stopRinging();
        Navigator.of(context).pop();
      }
    });
  }

  /// Rings the device: a pulsing vibration + alert tone every ~1.4s until the
  /// call is answered, declined or cancelled. Uses platform haptics/sounds so
  /// no audio asset or extra plugin is needed (no-op on web).
  void _startRinging() {
    void pulse() {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    }

    pulse();
    _ringTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) => pulse());
  }

  void _stopRinging() {
    _ringTimer?.cancel();
    _ringTimer = null;
  }

  @override
  void dispose() {
    _stopRinging();
    _stateSub?.cancel();
    super.dispose();
  }

  SpeekUser get _user =>
      widget.caller ??
      SpeekUser(
        id: widget.call.callerId,
        name: 'Speeker',
        age: 0,
        flag: '',
        country: '',
        city: '',
        role: SpeakerRole.learner,
        photoUrl: '',
      );

  Future<void> _accept() async {
    if (_busy) return;
    setState(() => _busy = true);
    _stopRinging();
    _stateSub?.cancel(); // don't let a callState event pop us mid-accept
    CallData call = widget.call;
    try {
      call = await Repos.calls.accept(widget.call.id);
      debugPrint('[IncomingRingScreen] accept ok, callId=${call.id}');
    } catch (e) {
      debugPrint('[IncomingRingScreen] accept error: $e');
    }
    debugPrint('[IncomingRingScreen] mounted=$mounted');
    if (!mounted) return;
    debugPrint('[IncomingRingScreen] navigating to call screen');
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => widget.call.isVideo
          ? VideoCallScreen(user: _user, callData: call)
          : VoiceCallScreen(user: _user, callData: call),
    ));
  }

  Future<void> _decline() async {
    if (_busy) return;
    setState(() => _busy = true);
    _stopRinging();
    _stateSub?.cancel();
    await CallService.instance.decline(widget.call.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
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
                  _PulseAvatar(user: u),
                  const SizedBox(height: 22),
                  Text(u.name.isEmpty ? 'Incoming call' : '${u.name} ${u.flag}',
                      style: AppText.displayMd),
                  const SizedBox(height: 6),
                  Text(
                      widget.call.isVideo
                          ? 'Incoming video call…'
                          : 'Incoming voice call…',
                      style: AppText.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 14),
                  Pill(widget.call.isVideo ? '📹 Video call' : '🎙 Voice call',
                      bg: Colors.white.withValues(alpha: 0.15),
                      fg: Colors.white,
                      border: Colors.white.withValues(alpha: 0.25)),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _RingButton(
                          icon: Icons.call_end_rounded,
                          label: 'Decline',
                          color: AppColors.danger,
                          onTap: _busy ? null : _decline,
                        ),
                        _RingButton(
                          icon: Icons.call,
                          label: 'Accept',
                          color: AppColors.success,
                          onTap: _busy ? null : _accept,
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

class _RingButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _RingButton(
      {required this.icon,
      required this.label,
      required this.color,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 20),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 10),
          Text(label,
              style: AppText.label
                  .copyWith(color: Colors.white.withValues(alpha: 0.9))),
        ],
      ),
    );
  }
}

class _PulseAvatar extends StatefulWidget {
  final SpeekUser user;
  const _PulseAvatar({required this.user});
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
            builder: (_, _) => Container(
              width: 128 + _c.value * 60,
              height: 128 + _c.value * 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: (1 - _c.value) * 0.3)),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.3), width: 3),
            ),
            child: Avatar(widget.user.photoUrl, size: 128, name: widget.user.name),
          ),
        ],
      ),
    );
  }
}
