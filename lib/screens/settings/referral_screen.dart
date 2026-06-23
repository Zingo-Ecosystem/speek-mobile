import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/dto.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';

/// Invite hub — share your code, earn +10 days Premium per friend, and see
/// everyone you've brought in. Fully wired to the backend (`/api/referral`).
class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _load();
  }

  Future<void> _load() async {
    await AppState.instance.refreshReferral();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  String get _shareMessage =>
      'Join me on Speek 🌍 — practice speaking with people around the world.\n'
      'Use my invite code ${AppState.instance.referralCode} and we both get '
      '${AppState.referralRewardDays} days of Premium free!';

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.85),
                radius: 1.2,
                colors: [Color(0xFF2A1F5E), Color(0xFF0A0A0F)],
              ),
            ),
            child: RefreshIndicator(
              color: AppColors.brand300,
              backgroundColor: AppColors.bgSurface,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    EdgeInsets.fromLTRB(Insets.x5, topPad + 8, Insets.x5, Insets.x10),
                children: [
                  Row(
                    children: [
                      SquareIconButton(Icons.arrow_back,
                          onTap: () => Navigator.of(context).pop()),
                      const Spacer(),
                      _PremiumDaysPill(days: s.premiumDaysLeft),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _Hero(anim: _anim),
                  const SizedBox(height: 18),
                  Text('Invite friends,\nearn Premium free',
                      textAlign: TextAlign.center, style: AppText.h1),
                  const SizedBox(height: 10),
                  _RewardBanner(days: AppState.referralRewardDays),
                  const SizedBox(height: 22),

                  // Live stats
                  Row(
                    children: [
                      Expanded(
                          child: StatTile('${s.invitedFriends}', 'friends joined',
                              valueColor: AppColors.brand300)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: StatTile('+${s.referralPremiumDays}d',
                              'premium earned',
                              valueColor: AppColors.gold)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _CodeCard(
                    code: s.referralCode,
                    onCopy: () {
                      Clipboard.setData(ClipboardData(text: s.referralCode));
                      showSnack(context, 'Invite code copied',
                          type: SnackType.success);
                    },
                    onShare: () => SharePlus.instance.share(ShareParams(text: _shareMessage, subject: 'Join me on Speek')),
                  ),
                  const SizedBox(height: 24),

                  // Who you've brought in
                  _SectionHeader(
                      title: 'People you brought in',
                      trailing: s.invitedFriends > 0
                          ? '${s.invitedFriends}'
                          : null),
                  const SizedBox(height: 12),
                  if (_loading)
                    const _ListSkeleton()
                  else if (s.invitedPeople.isEmpty)
                    const _EmptyInvites()
                  else
                    ...s.invitedPeople.map((f) => _InvitedTile(f)),

                  const SizedBox(height: 26),

                  // How it works
                  _SectionHeader(title: 'How it works'),
                  const SizedBox(height: 14),
                  _step('1', 'Share your code',
                      'Send your personal invite code to friends.'),
                  _step('2', 'They sign up',
                      'Your friend creates an account using your code.'),
                  _step(
                      '3',
                      'You both win',
                      'You each get ${AppState.referralRewardDays} days of '
                          'Premium — instantly.'),
                  const SizedBox(height: 8),

                  PrimaryButton('Share invite link',
                      gradient: AppColors.grad,
                      leading: const Icon(Icons.ios_share_rounded,
                          size: 18, color: Colors.white),
                      onTap: () => SharePlus.instance.share(ShareParams(text: _shareMessage, subject: 'Join me on Speek'))),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _step(String n, String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  gradient: AppColors.grad, shape: BoxShape.circle),
              child:
                  Text(n, style: AppText.label.copyWith(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.label),
                  const SizedBox(height: 2),
                  Text(body, style: AppText.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Hero: gift box with orbiting +10d reward chips
// ---------------------------------------------------------------------------
class _Hero extends StatelessWidget {
  final Animation<double> anim;
  const _Hero({required this.anim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, _) {
          final t = anim.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Glow halo
              Container(
                width: 130 + 12 * t,
                height: 130 + 12 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppColors.brand500.withValues(alpha: 0.35),
                    Colors.transparent,
                  ]),
                ),
              ),
              // Floating reward chips
              Transform.translate(
                offset: Offset(-64, -34 - 6 * t),
                child: _FloatChip('+10d', AppColors.gold),
              ),
              Transform.translate(
                offset: Offset(70, -18 + 6 * t),
                child: _FloatChip('Premium', AppColors.brand300),
              ),
              Transform.translate(
                offset: Offset(54, 44 - 5 * t),
                child: _FloatChip('Free', AppColors.success),
              ),
              Transform.translate(
                offset: Offset(0, -3 * t),
                child: const Text('🎁', style: TextStyle(fontSize: 68)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FloatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _FloatChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: AppText.caption
              .copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

// ---------------------------------------------------------------------------
class _RewardBanner extends StatelessWidget {
  final int days;
  const _RewardBanner({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          AppColors.gold.withValues(alpha: 0.18),
          AppColors.brand500.withValues(alpha: 0.14),
        ]),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Flexible(
            child: Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Every friend = '),
                TextSpan(
                    text: '+$days days',
                    style: TextStyle(
                        color: AppColors.gold, fontWeight: FontWeight.w800)),
                const TextSpan(text: ' Premium — for both of you'),
              ]),
              textAlign: TextAlign.center,
              style: AppText.bodyMuted.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _CodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onCopy, onShare;
  const _CodeCard(
      {required this.code, required this.onCopy, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brand500.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text('YOUR INVITE CODE',
              style: AppText.caption.copyWith(fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          // Dashed-style code chip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.brand500.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.brand400.withValues(alpha: 0.5), width: 1.4),
            ),
            child: Text(code,
                textAlign: TextAlign.center,
                style: AppText.displayMd
                    .copyWith(fontSize: 30, letterSpacing: 5)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GhostButton('Copy',
                    small: true,
                    leading: const Icon(Icons.copy_rounded,
                        size: 16, color: Colors.white),
                    onTap: onCopy),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton('Share',
                    small: true,
                    leading: const Icon(Icons.ios_share_rounded,
                        size: 16, color: Colors.white),
                    onTap: onShare),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppText.h3.copyWith(fontSize: 17)),
        const Spacer(),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brand500.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(trailing!,
                style: AppText.caption.copyWith(
                    color: AppColors.brand200, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
class _InvitedTile extends StatelessWidget {
  final InvitedFriend f;
  const _InvitedTile(this.f);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          _Avatar(f: f),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        f.name.isEmpty ? 'New Speeker' : f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label,
                      ),
                    ),
                    if (f.flag.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(f.flag, style: const TextStyle(fontSize: 14)),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  f.isOnboarded
                      ? 'Joined ${_ago(f.joinedAt)}'
                      : 'Signing up · ${_ago(f.joinedAt)}',
                  style: AppText.caption.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
            ),
            child: Text('+${f.rewardDays}d',
                style: AppText.caption.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  static String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

class _Avatar extends StatelessWidget {
  final InvitedFriend f;
  const _Avatar({required this.f});

  @override
  Widget build(BuildContext context) {
    const size = 46.0;
    final initial =
        (f.name.isNotEmpty ? f.name[0] : '?').toUpperCase();
    final placeholder = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
          gradient: AppColors.grad, shape: BoxShape.circle),
      child: Text(initial,
          style: AppText.h3.copyWith(color: Colors.white, fontSize: 18)),
    );
    if (f.photoUrl == null) return placeholder;
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: f.photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _EmptyInvites extends StatelessWidget {
  const _EmptyInvites();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(Radii.lg),
        border: Border.all(
            color: AppColors.borderSubtle, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Text('👋', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text('No friends yet',
              style: AppText.label, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
              'Share your code to bring your first friend in — '
              'and grab +${AppState.referralRewardDays} days of Premium.',
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(fontSize: 12)),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar(double w, double h) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(120, 12),
                  const SizedBox(height: 8),
                  bar(80, 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _PremiumDaysPill extends StatelessWidget {
  final int days;
  const _PremiumDaysPill({required this.days});

  @override
  Widget build(BuildContext context) {
    if (days <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('👑', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text('$days days left',
              style: AppText.caption.copyWith(
                  color: AppColors.gold, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
