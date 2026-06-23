import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../settings/referral_screen.dart';
import '../settings/settings_screen.dart';
import '../store/marketplace_screen.dart';
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
    final coverUrl = s.photoUrl;
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
                coverUrl.isNotEmpty
                    ? Image.network(coverUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _CoverGradient())
                    : const _CoverGradient(),
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
                  // Full-width name (wraps instead of clipping), then status
                  // chips on their own line so nothing gets cut off.
                  Text('${s.name}, ${s.age}  $flag',
                      style: AppText.displayMd.copyWith(fontSize: 23, height: 1.1),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (s.isPremium) const PremiumChip(small: true),
                      Pill('● Online',
                          bg: AppColors.success.withValues(alpha: 0.15),
                          fg: AppColors.success,
                          border: AppColors.success.withValues(alpha: 0.4)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(roleLine, style: AppText.smMuted),
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

                  // Invite & earn — full section
                  _InviteCard(
                    s,
                    onOpen: () => _push(context, const ReferralScreen()),
                  ),
                  const SizedBox(height: 14),

                  // XP marketplace entry (journey lives in the navbar now)
                  _MarketplaceCard(
                    balance: s.xpBalance,
                    onTap: () => _push(context, const MarketplaceScreen()),
                  ),
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

/// Branded cover used when the user hasn't uploaded a photo yet.
class _CoverGradient extends StatelessWidget {
  const _CoverGradient();
  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF241F4D), Color(0xFF0F0E1A)],
        ),
      ),
      alignment: const Alignment(0, -0.15),
      child: Avatar('', size: 96, name: s.name),
    );
  }
}

/// Full-width XP marketplace entry on the profile.
class _MarketplaceCard extends StatelessWidget {
  final int balance;
  final VoidCallback onTap;
  const _MarketplaceCard({required this.balance, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.gold.withValues(alpha: 0.18),
              AppColors.brand500.withValues(alpha: 0.16),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  gradient: AppColors.gradGold, shape: BoxShape.circle),
              child: const Text('🛍', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('XP Marketplace',
                      style: AppText.label.copyWith(color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('Spend your XP on avatars, themes & premium',
                      style: AppText.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('⚡ $balance',
                    style: AppText.label.copyWith(color: AppColors.gold)),
                Text('XP',
                    style: AppText.caption
                        .copyWith(fontSize: 10, color: AppColors.sText3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full invite section on the profile: explains the +10-days reward, shows how
/// many friends joined (with avatar stack), and opens the full referral hub.
class _InviteCard extends StatelessWidget {
  final AppState s;
  final VoidCallback onOpen;
  const _InviteCard(this.s, {required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final people = s.invitedPeople;
    final earned = s.referralPremiumDays;
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.brand600.withValues(alpha: 0.55),
              AppColors.brand900.withValues(alpha: 0.55),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.brand500.withValues(alpha: 0.45)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('🎁', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invite friends, earn Premium',
                          style: AppText.label.copyWith(color: Colors.white)),
                      const SizedBox(height: 3),
                      Text.rich(
                        TextSpan(children: [
                          const TextSpan(text: 'Get '),
                          TextSpan(
                              text: '+${AppState.referralRewardDays} days',
                              style: TextStyle(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.w800)),
                          const TextSpan(text: ' free for every friend'),
                        ]),
                        style: AppText.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.8)),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.10)),
            const SizedBox(height: 12),
            Row(
              children: [
                if (people.isNotEmpty) _AvatarStack(people: people),
                if (people.isNotEmpty) const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    people.isEmpty
                        ? 'No friends invited yet — tap to start'
                        : '${s.invitedFriends} joined · +${earned}d earned',
                    style: AppText.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12.5),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Invite',
                      style: AppText.caption.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Overlapping avatar stack of up to 4 invited friends.
class _AvatarStack extends StatelessWidget {
  final List people;
  const _AvatarStack({required this.people});

  @override
  Widget build(BuildContext context) {
    final show = people.take(4).toList();
    const d = 28.0;
    const overlap = 18.0;
    return SizedBox(
      width: overlap * (show.length - 1) + d,
      height: d,
      child: Stack(
        children: [
          for (int i = 0; i < show.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                width: d,
                height: d,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brand900, width: 1.6),
                  gradient: AppColors.grad,
                ),
                child: ClipOval(
                  child: show[i].photoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: show[i].photoUrl!,
                          width: d,
                          height: d,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _initial(show[i].name),
                        )
                      : _initial(show[i].name),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _initial(String name) => Center(
        child: Text(
          (name.isNotEmpty ? name[0] : '?').toUpperCase(),
          style: AppText.caption
              .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      );
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
