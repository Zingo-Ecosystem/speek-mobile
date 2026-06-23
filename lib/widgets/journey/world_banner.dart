import 'package:flutter/material.dart';

import '../../models/journey_world.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';

/// The header card that introduces each world: story, theme identity, progress,
/// and a clear locked / active / completed state.
class WorldBanner extends StatelessWidget {
  final JourneyWorld world;
  const WorldBanner({super.key, required this.world});

  @override
  Widget build(BuildContext context) {
    final theme = world.theme;
    final locked = world.isLocked;
    final done = world.isCompleted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.x5, 28, Insets.x5, 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: locked
                ? [AppColors.n500, AppColors.n600]
                : theme.gradient,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: locked
              ? null
              : [
                  BoxShadow(
                      color: theme.color.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10)),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _emblem(theme, locked),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WORLD ${theme.index + 1}',
                          style: AppText.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text(theme.name,
                          style: AppText.h2.copyWith(color: Colors.white)),
                      Text(theme.tagline,
                          style: AppText.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
                _statusPill(locked, done, world.completedInWorld, world.total),
              ],
            ),
            const SizedBox(height: 14),
            Text(theme.story,
                style: AppText.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.45,
                    fontSize: 12)),
            const SizedBox(height: 14),
            if (locked)
              _lockedFooter()
            else ...[
              _progressBar(),
              const SizedBox(height: 12),
              _skillsRow(theme),
              const SizedBox(height: 12),
              _rewardRow(theme, done),
            ],
          ],
        ),
      ),
    );
  }

  Widget _emblem(WorldTheme theme, bool locked) => Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: locked
            ? const Icon(Icons.lock_rounded, color: Colors.white, size: 26)
            : Text(theme.emoji, style: const TextStyle(fontSize: 30)),
      );

  Widget _statusPill(bool locked, bool done, int completed, int total) {
    final (label, color) = locked
        ? ('LOCKED', Colors.white.withValues(alpha: 0.7))
        : done
            ? ('COMPLETE ✓', Colors.white)
            : ('$completed/$total', Colors.white);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppText.caption.copyWith(
              color: color, fontWeight: FontWeight.w800, fontSize: 11)),
    );
  }

  Widget _progressBar() => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(children: [
          Container(height: 9, color: Colors.black.withValues(alpha: 0.22)),
          FractionallySizedBox(
            widthFactor: world.progress.clamp(0.0, 1.0),
            child: Container(height: 9, color: Colors.white),
          ),
        ]),
      );

  Widget _skillsRow(WorldTheme theme) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final s in theme.skills)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(s,
                  style: AppText.caption.copyWith(
                      color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
            ),
        ],
      );

  Widget _rewardRow(WorldTheme theme, bool done) => Row(
        children: [
          Text(done ? '🏆' : '🎁', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              done ? 'Claimed: ${theme.completionReward}' : 'Reward: ${theme.completionReward}',
              style: AppText.caption.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11.5),
            ),
          ),
        ],
      );

  Widget _lockedFooter() => Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              world.unlockRequirements.isNotEmpty
                  ? 'Unlock by: ${world.unlockRequirements.first.label}'
                  : 'Keep going to unlock this world',
              style: AppText.caption.copyWith(color: Colors.white70, fontSize: 11.5),
            ),
          ),
        ],
      );
}
