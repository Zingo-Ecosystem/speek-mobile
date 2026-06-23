import 'package:flutter/material.dart';

import '../../models/journey_world.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../common.dart';

/// Rich bottom sheet that answers, for any node: what to do, the reward, the
/// difficulty, the skills gained and — for the active node — exactly what's
/// left to unlock the next one (animated checklist).
class NodeDetailSheet extends StatelessWidget {
  final WorldNode node;
  final WorldTheme theme;
  final VoidCallback onPrimary;
  final String primaryLabel;
  const NodeDetailSheet({
    super.key,
    required this.node,
    required this.theme,
    required this.onPrimary,
    required this.primaryLabel,
  });

  static Future<void> show(
    BuildContext context, {
    required WorldNode node,
    required WorldTheme theme,
    required VoidCallback onPrimary,
    required String primaryLabel,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NodeDetailSheet(
        node: node,
        theme: theme,
        onPrimary: onPrimary,
        primaryLabel: primaryLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.sText3, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          _headerRow(),
          const SizedBox(height: 16),
          Text(node.objective,
              style: AppText.body.copyWith(color: AppColors.sText3, height: 1.4)),
          const SizedBox(height: 18),
          _statStrip(),
          const SizedBox(height: 16),
          _skills(),
          if (node.requirements.isNotEmpty) ...[
            const SizedBox(height: 18),
            _unlockChecklist(),
          ],
          const SizedBox(height: 22),
          if (!node.isLocked)
            PrimaryButton(
              primaryLabel,
              gradient: node.isActive ? AppColors.gradGold : AppColors.grad,
              textColor: node.isActive ? const Color(0xFF3A2600) : Colors.white,
              onTap: () {
                Navigator.of(context).pop();
                onPrimary();
              },
            )
          else
            _lockedBanner(),
        ],
      ),
    );
  }

  Widget _headerRow() {
    final badge = switch (node.kind) {
      NodeKind.milestone => ('👑', 'World Boss'),
      NodeKind.checkpoint => ('🎯', 'Speaking Challenge'),
      NodeKind.lesson => (theme.emoji, 'Lesson'),
    };
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: theme.gradient),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(badge.$1, style: const TextStyle(fontSize: 28)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('DAY ${node.day} · ${badge.$2.toUpperCase()}',
                  style: AppText.caption.copyWith(
                      color: theme.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8)),
              const SizedBox(height: 2),
              Text(node.title, style: AppText.h2),
            ],
          ),
        ),
        if (node.isCompleted)
          Icon(Icons.verified_rounded, color: AppColors.success, size: 28),
      ],
    );
  }

  Widget _statStrip() {
    Widget stat(String emoji, String value, String label, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.sFill(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(value,
                  style: AppText.label.copyWith(color: color, fontWeight: FontWeight.w800)),
              Text(label, style: AppText.caption.copyWith(fontSize: 10, color: AppColors.sText3)),
            ]),
          ),
        );
    return Row(children: [
      stat('⚡', '+${node.xpReward}', 'XP', AppColors.gold),
      const SizedBox(width: 10),
      stat('⏱', '${node.estimatedMinutes}m', 'Duration', AppColors.cyan),
      const SizedBox(width: 10),
      _difficultyStat(),
    ]);
  }

  Widget _difficultyStat() => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.sFill(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  4,
                  (i) => Container(
                        width: 5,
                        height: 14 - (3 - i).abs() * 0.0 + i * 2.0,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: i < node.difficulty.bars
                              ? node.difficulty.color
                              : AppColors.sFill(0.12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      )),
            ),
            const SizedBox(height: 6),
            Text(node.difficulty.label,
                style: AppText.label.copyWith(
                    color: node.difficulty.color, fontWeight: FontWeight.w800)),
            Text('Difficulty',
                style: AppText.caption.copyWith(fontSize: 10, color: AppColors.sText3)),
          ]),
        ),
      );

  Widget _skills() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skills you gain', style: AppText.label),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in node.skills)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: theme.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.color.withValues(alpha: 0.4)),
                ),
                child: Text(s,
                    style: AppText.caption.copyWith(
                        color: theme.color, fontWeight: FontWeight.w700)),
              ),
          ]),
        ],
      );

  Widget _unlockChecklist() {
    final done = node.requirements.where((r) => r.done).length;
    final pct = (node.unlockProgress * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sFill(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lock_open_rounded, size: 16, color: AppColors.warning),
            const SizedBox(width: 6),
            Text('Unlock next day', style: AppText.label),
            const Spacer(),
            Text('$pct%',
                style: AppText.label.copyWith(
                    color: AppColors.warning, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: node.unlockProgress),
              builder: (_, v, __) => Stack(children: [
                Container(height: 8, color: AppColors.sFill(0.12)),
                FractionallySizedBox(
                  widthFactor: v,
                  child: Container(
                      height: 8,
                      decoration: const BoxDecoration(gradient: AppColors.gradGold)),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          for (final r in node.requirements) _reqRow(r),
          const SizedBox(height: 4),
          Text('$done of ${node.requirements.length} complete',
              style: AppText.caption.copyWith(color: AppColors.sText3, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _reqRow(UnlockRequirement r) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: r.done
                  ? AppColors.success.withValues(alpha: 0.18)
                  : AppColors.sFill(0.08),
              shape: BoxShape.circle,
              border: Border.all(
                  color: r.done ? AppColors.success : AppColors.borderStrong),
            ),
            child: r.done
                ? Icon(Icons.check_rounded, size: 14, color: AppColors.success)
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(r.label,
                style: AppText.caption.copyWith(
                    color: r.done ? AppColors.sText3 : null,
                    decoration: r.done ? TextDecoration.lineThrough : null)),
          ),
        ]),
      );

  Widget _lockedBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.sFill(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(children: [
          const Icon(Icons.lock_rounded, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Complete the earlier days to unlock this one.',
                style: AppText.caption.copyWith(color: AppColors.sText3)),
          ),
        ]),
      );
}
