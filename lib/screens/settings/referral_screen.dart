import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        final topPad = MediaQuery.of(context).padding.top;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.8),
                radius: 1.1,
                colors: [Color(0xFF241F4D), Color(0xFF0A0A0F)],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                  Insets.x5, topPad + 8, Insets.x5, Insets.x10),
              children: [
                Row(
                  children: [
                    SquareIconButton(Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop()),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 8),
                Center(child: const Text('🎁', style: TextStyle(fontSize: 56))),
                const SizedBox(height: 12),
                Text('Invite friends,\nget Premium free',
                    textAlign: TextAlign.center, style: AppText.h1),
                const SizedBox(height: 10),
                Text(
                    'For every friend who joins with your code, you both get '
                    '${AppState.referralRewardDays} days of Speek Premium.',
                    textAlign: TextAlign.center,
                    style: AppText.bodyMuted),
                const SizedBox(height: 24),

                // Stats
                Row(
                  children: [
                    Expanded(
                        child: StatTile('${s.invitedFriends}', 'friends joined',
                            valueColor: AppColors.brand300)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: StatTile('${s.referralPremiumDays}d',
                            'premium earned',
                            valueColor: AppColors.gold)),
                  ],
                ),
                const SizedBox(height: 20),

                // Code card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.brand500.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    children: [
                      Text('YOUR INVITE CODE',
                          style: AppText.caption.copyWith(fontSize: 11)),
                      const SizedBox(height: 8),
                      Text(s.referralCode,
                          style: AppText.displayMd.copyWith(
                              fontSize: 28, letterSpacing: 4)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: GhostButton('Copy code', small: true,
                                leading: const Icon(Icons.copy_rounded,
                                    size: 16, color: Colors.white),
                                onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: s.referralCode));
                              showSnack(context, 'Invite code copied',
                                  type: SnackType.success);
                            }),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: PrimaryButton('Share', small: true,
                                leading: const Icon(Icons.ios_share_rounded,
                                    size: 16, color: Colors.white),
                                onTap: () {
                              showSnack(context,
                                  'Share: "Join me on Speek! Code ${s.referralCode}"');
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // How it works
                _step('1', 'Share your code',
                    'Send your invite code to friends.'),
                _step('2', 'They sign up',
                    'Your friend creates an account with your code.'),
                _step('3', 'You both win',
                    'You each get ${AppState.referralRewardDays} days of Premium, instantly.'),

                const SizedBox(height: 20),
                // Demo button to show the mechanism working end-to-end.
                PrimaryButton('Simulate a friend joining',
                    gradient: AppColors.gradGold,
                    textColor: const Color(0xFF3A2600), onTap: () {
                  s.redeemInvite();
                  showSnack(context,
                      '🎉 +${AppState.referralRewardDays} days Premium! ${s.premiumDaysLeft} days left.',
                      type: SnackType.success);
                }),
              ],
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
              child: Text(n,
                  style: AppText.label.copyWith(color: Colors.white)),
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
