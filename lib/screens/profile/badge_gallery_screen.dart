import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';

class BadgeGalleryScreen extends StatelessWidget {
  const BadgeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        final categories = <String>['Speaking', 'Streak', 'Global', 'Level'];
        return AdaptiveScaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Insets.x4, Insets.x4, Insets.x4, 14),
                  child: Row(
                    children: [
                      SquareIconButton(Icons.arrow_back,
                          onTap: () => Navigator.of(context).pop()),
                      Expanded(
                        child: Text('Your badges',
                            textAlign: TextAlign.center,
                            style: AppText.h3.copyWith(fontSize: 16)),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        Insets.x5, 0, Insets.x5, Insets.x8),
                    children: [
                      _summary(s),
                      for (final cat in categories)
                        _section(context, s, cat),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _summary(AppState s) {
    final total = AppState.badges.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          gradient: AppColors.gradDeep,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 6),
          Text('${s.unlockedBadgeCount} of $total unlocked',
              style: AppText.h2.copyWith(fontSize: 20)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 7, color: AppColors.sFill(0.2)),
                FractionallySizedBox(
                  widthFactor: s.unlockedBadgeCount / total,
                  child: Container(height: 7, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, AppState s, String category) {
    final items =
        AppState.badges.where((b) => b.category == category).toList();
    final done = items.where((b) => b.unlocked(s)).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 22, 0, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: AppText.h3),
              Text('$done/${items.length}', style: AppText.smMuted),
            ],
          ),
        ),
        for (final b in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _showBadge(context, s, b),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: BadgeTile(
                      emoji: b.unlocked(s) ? b.emoji : '🔒',
                      label: b.label,
                      color: b.color,
                      locked: !b.unlocked(s),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(b.label, style: AppText.label),
                            if (b.unlocked(s)) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified,
                                  size: 15, color: AppColors.success),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(b.howTo, style: AppText.caption.copyWith(fontSize: 12)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Stack(
                            children: [
                              Container(
                                  height: 6,
                                  color: AppColors.sFill(0.08)),
                              FractionallySizedBox(
                                widthFactor: b.ratio(s),
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: b.unlocked(s)
                                          ? AppColors.success
                                          : AppColors.brand500),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            '${b.progress(s).clamp(0, b.target)} / ${b.target}',
                            style: AppText.caption.copyWith(fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showBadge(BuildContext context, AppState s, dynamic b) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(b.unlocked(s)
          ? '${b.emoji} ${b.label} — unlocked!'
          : '🔒 ${b.label} — ${b.howTo}'),
      backgroundColor: AppColors.n700,
      behavior: SnackBarBehavior.floating,
    ));
  }
}
