import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  static const _groups = [
    (
      'Messages & calls',
      [
        ('messages', '💬', 'New messages', 'When someone sends you a message'),
        ('requests', '🙋', 'Message requests', 'When someone wants to chat'),
        ('calls', '📞', 'Incoming calls', 'When someone calls you'),
        ('missed', '📵', 'Missed calls', 'Reminders for calls you missed'),
      ],
    ),
    (
      'Social',
      [
        ('likes', '💜', 'Likes & views', 'When someone likes or views you'),
      ],
    ),
    (
      'Progress',
      [
        ('streak', '🔥', 'Streak reminders', 'Don\'t lose your daily streak'),
        ('badges', '🏆', 'XP & badges', 'When you earn XP or unlock a badge'),
      ],
    ),
    (
      'Other',
      [
        ('promos', '📣', 'News & offers', 'Product updates and promotions'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        final topPad = MediaQuery.of(context).padding.top;
        return AdaptiveScaffold(
          body: ListView(
            padding: EdgeInsets.fromLTRB(0, topPad + 8, 0, Insets.x10),
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(Insets.x4, 0, Insets.x4, 14),
                child: Row(
                  children: [
                    SquareIconButton(Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop()),
                    Expanded(
                      child: Text('Notifications',
                          textAlign: TextAlign.center,
                          style: AppText.h3.copyWith(fontSize: 16)),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
              ),
              for (final g in _groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(Insets.x5, 18, Insets.x5, 8),
                  child: Text(g.$1.toUpperCase(),
                      style: AppText.label.copyWith(
                          color: AppColors.sText3, fontSize: 12)),
                ),
                for (final item in g.$2)
                  _NotifTile(
                    emoji: item.$2,
                    title: item.$3,
                    subtitle: item.$4,
                    value: s.notifications[item.$1] ?? false,
                    onChanged: (v) => s.toggleNotification(item.$1, v),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _NotifTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.x5, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sFill(0.05),
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.label),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.caption.copyWith(fontSize: 11.5)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.brand500,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
