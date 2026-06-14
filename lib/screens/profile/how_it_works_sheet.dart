import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';

/// Explains the gamification mechanics: XP, levels, streaks and badges.
Future<void> showHowItWorks(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _HowItWorksSheet(),
  );
}

class _HowItWorksSheet extends StatelessWidget {
  const _HowItWorksSheet();

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82),
      decoration: BoxDecoration(
        color: AppColors.sSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: const Border(top: BorderSide(color: Color(0x4D6C63FF))),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: AppColors.sText),
        child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Insets.x6, 12, Insets.x6, Insets.x8),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                    color: AppColors.sFill(0.2),
                    borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 18),
            Text('How progress works', style: AppText.h2),
            const SizedBox(height: 6),
            Text('Speek rewards you for talking. Here\'s how.',
                style: AppText.bodyMuted),
            const SizedBox(height: 22),
            _block('⚡', 'XP & levels',
                'You earn 15 XP per minute on every call (40 XP minimum). '
                'Every ${s.xpForLevel} XP levels you up. You\'re level ${s.gLevel} '
                'with ${s.totalXp} XP total.'),
            _block('🔥', 'Daily streak',
                'Talk to at least one person each day to grow your streak. '
                'Miss a day and it resets. Your streak is ${s.streakDays} days.'),
            _block('🌍', 'Countries',
                'Every new country you talk to counts toward global badges. '
                'You\'ve reached ${s.countriesSpoken.length} so far.'),
            _block('🏆', 'Badges',
                'Hit milestones — calls, streaks, countries, levels — to unlock '
                'badges. You\'ve unlocked ${s.unlockedBadgeCount} of '
                '${AppState.badges.length}.'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.brand500.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppColors.brand500.withValues(alpha: 0.3)),
              ),
              child: Text('💡 Tip: a quick daily call keeps your streak alive '
                  'and stacks XP fast.',
                  style: AppText.label.copyWith(color: AppColors.brand200)),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _block(String emoji, String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.h3.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(body, style: AppText.body.copyWith(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );
}
