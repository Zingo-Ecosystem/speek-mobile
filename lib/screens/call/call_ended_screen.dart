import 'package:flutter/material.dart';

import '../../data/repositories.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';

class CallEndedScreen extends StatefulWidget {
  final SpeekUser user;
  final Duration duration;
  final String? callId;
  const CallEndedScreen({
    super.key,
    required this.user,
    this.duration = Duration.zero,
    this.callId,
  });

  @override
  State<CallEndedScreen> createState() => _CallEndedScreenState();
}

class _CallEndedScreenState extends State<CallEndedScreen> {
  int _rating = 5;
  int _xpEarned = 0;
  bool _friendAdded = false;
  bool _busy = false;

  String get _durationText {
    final s = widget.duration.inSeconds;
    final m = s ~/ 60;
    final sec = s % 60;
    return m > 0 ? '$m min ${sec.toString().padLeft(2, '0')} s' : '$s s';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _xpEarned = AppState.instance.recordCall(
          country: widget.user.country,
          minutes: widget.duration.inMinutes,
        );
      });
    });
  }

  Future<void> _submitRating() async {
    final id = widget.callId;
    if (id == null || id.isEmpty) return;
    try {
      await Repos.calls.rate(id, _rating);
    } catch (_) {}
  }

  Future<void> _addFriend() async {
    if (_busy || _friendAdded) return;
    setState(() => _busy = true);
    try {
      await _submitRating();
      await Repos.friends.addOrAccept(widget.user.id);
      if (!mounted) return;
      setState(() {
        _friendAdded = true;
        _busy = false;
      });
      showSnack(context, 'Friend request sent to ${widget.user.name}!');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showSnack(context, 'Could not send friend request.', type: SnackType.error);
    }
  }

  Future<void> _done() async {
    await _submitRating();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.7),
            radius: 1.1,
            colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0F)],
          ),
        ),
        child: Stack(
          children: [
            const BrandGlow(opacity: 0.5),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.x6),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3), width: 2),
                      ),
                      child: Avatar(u.photoUrl, size: 84),
                    ),
                    const SizedBox(height: 14),
                    Text('Call ended', style: AppText.h2),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        style: AppText.smMuted,
                        children: [
                          TextSpan(text: 'You spoke with ${u.name} for '),
                          TextSpan(
                              text: _durationText,
                              style: AppText.smMuted.copyWith(
                                  color: AppColors.brand300,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.brand500.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: AppColors.brand500.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                          '🎉 +$_xpEarned XP earned · 🔥 ${AppState.instance.streakDays}-day streak',
                          textAlign: TextAlign.center,
                          style: AppText.label
                              .copyWith(color: AppColors.brand200)),
                    ),
                    const SizedBox(height: 24),
                    Text('How was your conversation?', style: AppText.h3),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 1; i <= 5; i++)
                          GestureDetector(
                            onTap: () => setState(() => _rating = i),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                i <= _rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: AppColors.gold,
                                size: 38,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(flex: 3),
                    _busy
                        ? const SizedBox(
                            height: 52,
                            child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2)))
                        : PrimaryButton(
                            _friendAdded
                                ? '✓ Friend request sent'
                                : '💜 Add ${u.name} as friend',
                            onTap: _friendAdded ? null : _addFriend,
                          ),
                    const SizedBox(height: 12),
                    GhostButton('Back to map', onTap: _done),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
