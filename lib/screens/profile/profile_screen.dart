import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../settings/referral_screen.dart';
import '../settings/settings_screen.dart';
import '../subscription/manage_subscription_screen.dart';
import '../subscription/paywall_screen.dart';
import 'badge_gallery_screen.dart';
import 'edit_profile_screen.dart';
import 'how_it_works_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) => _build(context),
    );
  }

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Widget _build(BuildContext context) {
    final s = AppState.instance;
    final me = Mock.me;
    final flag = s.country.split(' ').first;
    final roleLine = s.isLearner
        ? 'Learner · ${s.city} · ${s.level} → fluent goal'
        : 'Native · ${s.city}';
    final topPad = MediaQuery.of(context).padding.top;
    final unlocked = AppState.badges.where((b) => b.unlocked(s)).take(4).toList();
    final preview = unlocked.length >= 4
        ? unlocked
        : [...unlocked, ...AppState.badges.where((b) => !b.unlocked(s))]
            .take(4)
            .toList();

    return AdaptiveScaffold(
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          // Cover
          SizedBox(
            height: 228,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(me.photoUrl, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.transparent,
                        AppColors.sBg,
                      ],
                      stops: const [0, 0.4, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: topPad + 8,
                  right: 18,
                  child: Row(
                    children: [
                      SquareIconButton(Icons.edit_outlined,
                          bg: const Color(0x66000000),
                          onTap: () => _push(context, const EditProfileScreen())),
                      const SizedBox(width: 10),
                      SquareIconButton(Icons.settings_outlined,
                          bg: const Color(0x66000000),
                          onTap: () => _push(context, const SettingsScreen())),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text('${s.name}, ${s.age}  $flag',
                                      style: AppText.displayMd
                                          .copyWith(fontSize: 25),
                                      overflow: TextOverflow.ellipsis),
                                ),
                                if (s.isPremium) ...[
                                  const SizedBox(width: 8),
                                  const PremiumChip(small: true),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(roleLine, style: AppText.smMuted),
                          ],
                        ),
                      ),
                      Pill('● Online',
                          bg: AppColors.success.withValues(alpha: 0.15),
                          fg: AppColors.success,
                          border: AppColors.success.withValues(alpha: 0.4)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: StatTile('🔥 ${s.streakDays}', 'day streak',
                              valueColor: AppColors.warning)),
                      const SizedBox(width: 10),
                      Expanded(child: StatTile('${s.totalCalls}', 'calls')),
                      const SizedBox(width: 10),
                      Expanded(
                          child: StatTile('Lv.${s.gLevel}',
                              '${s.totalXp} XP',
                              valueColor: AppColors.brand300)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _xpBar(context, s),
                  const SizedBox(height: 20),

                  // Premium vs free
                  s.isPremium ? _PremiumActiveCard(s) : _GoPremiumCard(),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text.rich(TextSpan(
                        style: AppText.h3,
                        children: [
                          const TextSpan(text: 'Badges '),
                          TextSpan(
                              text: '· ${s.unlockedBadgeCount}',
                              style: AppText.body.copyWith(
                                  color: AppColors.sText3, fontSize: 13)),
                        ],
                      )),
                      GestureDetector(
                        onTap: () =>
                            _push(context, const BadgeGalleryScreen()),
                        child: Text('See all',
                            style: AppText.label
                                .copyWith(color: AppColors.brand300)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 96,
                    child: Row(
                      children: [
                        for (int i = 0; i < preview.length; i++) ...[
                          Expanded(
                              child: GestureDetector(
                            onTap: () =>
                                _push(context, const BadgeGalleryScreen()),
                            child: BadgeTile(
                              emoji: preview[i].unlocked(s)
                                  ? preview[i].emoji
                                  : '🔒',
                              label: preview[i].label,
                              color: preview[i].color,
                              locked: !preview[i].unlocked(s),
                            ),
                          )),
                          if (i != preview.length - 1)
                            const SizedBox(width: 12),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _row(context, Icons.help_outline_rounded,
                      'How XP & streaks work',
                      () => showHowItWorks(context)),
                  _row(context, Icons.card_giftcard_rounded,
                      'Invite friends · earn Premium',
                      () => _push(context, const ReferralScreen()),
                      trailing: '+${AppState.referralRewardDays}d'),
                  _row(context, Icons.settings_outlined, 'Settings',
                      () => _push(context, const SettingsScreen())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _xpBar(BuildContext context, AppState s) => GestureDetector(
        onTap: () => showHowItWorks(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Level ${s.gLevel}',
                    style: AppText.caption.copyWith(fontSize: 11)),
                Text('${s.xpIntoLevel} / ${s.xpForLevel} XP',
                    style: AppText.caption.copyWith(fontSize: 11)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(
                      height: 8, color: AppColors.sFill(0.08)),
                  FractionallySizedBox(
                    widthFactor: s.levelProgress,
                    child: Container(
                      height: 8,
                      decoration: const BoxDecoration(gradient: AppColors.grad),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _row(BuildContext context, IconData icon, String label,
      VoidCallback onTap,
      {String? trailing}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.sFill(0.07))),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.sText),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppText.body)),
            if (trailing != null)
              Text(trailing,
                  style: AppText.caption
                      .copyWith(color: AppColors.success, fontSize: 13)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: AppColors.sText3, size: 20),
          ],
        ),
      ),
    );
  }
}

class _GoPremiumCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppColors.gradDeep,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 30)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Go Premium',
                      style: AppText.h3.copyWith(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Unlimited talks · see who likes you',
                      style: AppText.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _PremiumActiveCard extends StatelessWidget {
  final AppState s;
  const _PremiumActiveCard(this.s);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const ManageSubscriptionScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFFD66B).withValues(alpha: 0.16),
              const Color(0xFFF0A93B).withValues(alpha: 0.06),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  gradient: AppColors.gradGold, shape: BoxShape.circle),
              child: const Text('👑', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Premium active', style: AppText.h3),
                      if (s.fromTrial && !s.isSubscribed) ...[
                        const SizedBox(width: 8),
                        Text('Trial',
                            style: AppText.caption.copyWith(
                                color: AppColors.gold, fontSize: 11)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                      s.isSubscribed
                          ? 'Renews monthly · manage plan'
                          : '${s.premiumDaysLeft} days left · tap to manage',
                      style: AppText.caption.copyWith(
                          color: AppColors.sText2, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.sText3),
          ],
        ),
      ),
    );
  }
}
