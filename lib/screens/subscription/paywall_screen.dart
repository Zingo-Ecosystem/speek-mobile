import 'package:flutter/material.dart';

import '../../services/purchase_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _plan = 1; // 0 monthly, 1 yearly
  bool _busy = false;

  bool get _eligibleForTrial =>
      !AppState.instance.fromTrial && !AppState.instance.isSubscribed;

  String get _ctaLabel => _eligibleForTrial
      ? 'Start 14-day free trial'
      : _plan == 1
          ? 'Subscribe yearly · \$99'
          : 'Subscribe monthly · \$15';

  Future<void> _onCta() async {
    final s = AppState.instance;
    if (_eligibleForTrial) {
      s.startTrial();
      showSnack(context, '🎉 Your 14-day free trial is active!',
          type: SnackType.success);
      Navigator.of(context).pop();
      return;
    }
    setState(() => _busy = true);
    final res = await PurchaseService.instance.buy(yearly: _plan == 1);
    if (!mounted) return;
    setState(() => _busy = false);
    showSnack(context, res.message,
        type: res.ok ? SnackType.success : SnackType.error);
    if (res.ok) Navigator.of(context).pop();
  }

  static const _perks = [
    'Unlimited calls & messages',
    'See who viewed & liked you',
    'Priority on the map (boost)',
    'Advanced filters (level, country, goals)',
    'Exclusive premium badges',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1),
            radius: 1.2,
            colors: [Color(0xFF241F4D), Color(0xFF0A0A0F)],
          ),
        ),
        child: Stack(
          children: [
            const BrandGlow(),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 18, 0),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: AppColors.n300),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding:
                          const EdgeInsets.fromLTRB(Insets.x6, 8, Insets.x6, 0),
                      children: [
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: AppColors.gradGold,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFF0A93B)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 30,
                                    offset: const Offset(0, 12))
                              ],
                            ),
                            child: const Center(
                                child:
                                    Text('👑', style: TextStyle(fontSize: 30))),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(child: Text('Speek Premium', style: AppText.h1)),
                        const SizedBox(height: 8),
                        Text(
                            'Unlimited talks, see who likes you, and stand out worldwide.',
                            textAlign: TextAlign.center,
                            style: AppText.bodyMuted),
                        const SizedBox(height: 22),
                        for (final p in _perks) _perk(p),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Insets.x6, 8, Insets.x6, Insets.x6),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: _planCard(0, 'Monthly', '\$15', '/mo')),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _planCard(1, 'Yearly', '\$99', '\$8.25/mo',
                                    badge: 'SAVE 44%')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(_ctaLabel,
                            gradient: AppColors.gradGold,
                            textColor: const Color(0xFF3A2600),
                            shadow: [
                              BoxShadow(
                                  color: const Color(0xFFF0A93B)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 26,
                                  offset: const Offset(0, 10))
                            ],
                            onTap: _busy ? null : _onCta),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () async {
                            await PurchaseService.instance.restore();
                            if (context.mounted) {
                              showSnack(context, 'Restoring purchases…');
                            }
                          },
                          child: Text.rich(
                            TextSpan(
                              style: AppText.caption.copyWith(fontSize: 11),
                              children: [
                                const TextSpan(
                                    text: 'Then \$15/mo. Cancel anytime · '),
                                TextSpan(
                                    text: 'Restore',
                                    style: AppText.caption.copyWith(
                                        fontSize: 11,
                                        color: AppColors.brand300)),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _perk(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: AppText.body.copyWith(fontSize: 14))),
          ],
        ),
      );

  Widget _planCard(int i, String title, String price, String sub,
      {String? badge}) {
    final on = _plan == i;
    return GestureDetector(
      onTap: () => setState(() => _plan = i),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: on
              ? AppColors.brand500.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
              color: on ? AppColors.brand500 : Colors.white.withValues(alpha: 0.12),
              width: on ? 2 : 1),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                Text(title, style: AppText.smMuted),
                const SizedBox(height: 2),
                Text(price, style: AppText.h2.copyWith(fontSize: 18)),
                Text(sub, style: AppText.smMuted),
              ],
            ),
            if (badge != null)
              Positioned(
                top: -21,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        gradient: AppColors.gradGold,
                        borderRadius: BorderRadius.circular(100)),
                    child: Text(badge,
                        style: AppText.caption.copyWith(
                            color: const Color(0xFF3A2600),
                            fontSize: 9,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
