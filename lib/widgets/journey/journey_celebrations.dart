import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../common.dart';

/// Reusable celebration toolkit for the Journey: a confetti burst, a reward
/// dialog and an XP "+N" fly-up. Kept dependency-free (pure CustomPaint) so it
/// stays performant on low-end devices.

/// Shows a full-screen reward celebration with confetti behind a reward card.
Future<void> showRewardCelebration(
  BuildContext context, {
  required String emoji,
  required String title,
  required String subtitle,
  int xp = 0,
  int coins = 0,
  int gems = 0,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'reward',
    barrierColor: Colors.black.withValues(alpha: 0.62),
    transitionDuration: const Duration(milliseconds: 420),
    pageBuilder: (_, __, ___) => _RewardCelebration(
      emoji: emoji,
      title: title,
      subtitle: subtitle,
      xp: xp,
      coins: coins,
      gems: gems,
    ),
    transitionBuilder: (_, anim, __, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(scale: Tween(begin: 0.8, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

class _RewardCelebration extends StatefulWidget {
  final String emoji, title, subtitle;
  final int xp, coins, gems;
  const _RewardCelebration({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.xp,
    required this.coins,
    required this.gems,
  });

  @override
  State<_RewardCelebration> createState() => _RewardCelebrationState();
}

class _RewardCelebrationState extends State<_RewardCelebration>
    with TickerProviderStateMixin {
  late final AnimationController _confetti =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..forward();
  late final AnimationController _badge =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _confetti.dispose();
    _badge.dispose();
    super.dispose();
  }

  Widget _chip(String emoji, int value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text('+$value',
              style: AppText.label.copyWith(color: color, fontWeight: FontWeight.w900)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final rewards = <Widget>[
      if (widget.xp > 0) _chip('⚡', widget.xp, AppColors.gold),
      if (widget.coins > 0) _chip('🪙', widget.coins, const Color(0xFFFFC83D)),
      if (widget.gems > 0) _chip('💎', widget.gems, AppColors.cyan),
    ];

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _confetti,
            builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_confetti.value)),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF3A1E5E), Color(0xFF1A1430)],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _badge,
                    builder: (_, child) => Transform.scale(
                      scale: 1 + 0.06 * math.sin(_badge.value * math.pi * 2),
                      child: child,
                    ),
                    child: Text(widget.emoji, style: const TextStyle(fontSize: 72)),
                  ),
                  const SizedBox(height: 14),
                  Text(widget.title,
                      textAlign: TextAlign.center,
                      style: AppText.h2.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text(widget.subtitle,
                      textAlign: TextAlign.center,
                      style: AppText.caption.copyWith(color: Colors.white70)),
                  if (rewards.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: rewards),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton('Collect',
                      gradient: AppColors.gradGold,
                      textColor: const Color(0xFF3A2600),
                      onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lightweight falling-confetti painter driven by a 0..1 progress value.
class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  static final _rng = math.Random(7);
  static final _pieces = List.generate(60, (i) {
    return _Piece(
      x: _rng.nextDouble(),
      delay: _rng.nextDouble() * 0.3,
      speed: 0.7 + _rng.nextDouble() * 0.6,
      sway: 0.04 + _rng.nextDouble() * 0.08,
      size: 5 + _rng.nextDouble() * 7,
      rot: _rng.nextDouble() * math.pi,
      color: [
        const Color(0xFFFFD66B),
        const Color(0xFF6C63FF),
        const Color(0xFF45E07A),
        const Color(0xFF3DD6E0),
        const Color(0xFFFF6FB5),
      ][i % 5],
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in _pieces) {
      final local = ((t - p.delay) * p.speed).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final dy = local * (size.height + 40) - 40;
      final dx = p.x * size.width + math.sin(local * 8 + p.rot) * p.sway * size.width;
      paint.color = p.color.withValues(alpha: (1 - local).clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rot + local * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

class _Piece {
  final double x, delay, speed, sway, size, rot;
  final Color color;
  _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.sway,
    required this.size,
    required this.rot,
    required this.color,
  });
}
