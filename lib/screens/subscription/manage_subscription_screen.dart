import 'package:flutter/material.dart';

import '../../services/purchase_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';
import 'paywall_screen.dart';

class ManageSubscriptionScreen extends StatelessWidget {
  const ManageSubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        final status = s.isSubscribed
            ? '● Active'
            : s.fromTrial
                ? '● Trial (${s.premiumDaysLeft} days left)'
                : '● Premium (${s.premiumDaysLeft} days left)';
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Insets.x4, Insets.x4, Insets.x4, 14),
                  child: Row(
                    children: [
                      SquareIconButton(Icons.arrow_back,
                          onTap: () => Navigator.of(context).pop()),
                      Expanded(
                        child: Text('Subscription',
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
                      _currentPlanCard(s),
                      const SizedBox(height: 22),
                      _row('Plan',
                          s.isSubscribed ? 'Monthly · \$15' : 'Premium access'),
                      _row('Status', status, valueColor: AppColors.success),
                      _row('Payment', s.isSubscribed ? 'Apple Pay' : '—'),
                      _row(
                          'Premium days left', '${s.premiumDaysLeft} days',
                          valueColor: AppColors.gold),
                      const SizedBox(height: 22),
                      if (!s.isSubscribed)
                        PrimaryButton('Subscribe · \$15/mo', onTap: () async {
                          final res = await PurchaseService.instance
                              .buy(yearly: false);
                          if (context.mounted) {
                            showSnack(context, res.message,
                                type: res.ok
                                    ? SnackType.success
                                    : SnackType.error);
                          }
                        })
                      else
                        GhostButton('Switch to Yearly · save 44%',
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const PaywallScreen()))),
                      const SizedBox(height: 18),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            s.cancelSubscription();
                            _toast(context,
                                'Subscription cancelled. Premium stays until it expires.');
                          },
                          child: Text('Cancel subscription',
                              style: AppText.label
                                  .copyWith(color: AppColors.danger)),
                        ),
                      ),
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

  void _toast(BuildContext context, String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.n700,
        behavior: SnackBarBehavior.floating,
      ));

  Widget _currentPlanCard(AppState s) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            gradient: AppColors.gradDeep,
            borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            const Positioned(
                top: 0,
                right: 0,
                child: Text('👑', style: TextStyle(fontSize: 24))),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current plan',
                    style: AppText.caption
                        .copyWith(color: Colors.white.withValues(alpha: 0.8))),
                const SizedBox(height: 4),
                Text(
                    s.isSubscribed
                        ? 'Premium · Subscribed'
                        : s.fromTrial
                            ? 'Premium · Free trial'
                            : 'Premium',
                    style: AppText.h2.copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                Text('${s.premiumDaysLeft} days of premium remaining',
                    style: AppText.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ],
        ),
      );

  Widget _row(String label, String value, {Color? valueColor}) => Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    AppText.body.copyWith(color: AppColors.n300, fontSize: 14)),
            Text(value,
                style: AppText.label
                    .copyWith(color: valueColor ?? AppColors.textPrimary)),
          ],
        ),
      );
}
