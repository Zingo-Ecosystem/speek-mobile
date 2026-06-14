import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../profile/edit_profile_screen.dart';
import '../subscription/manage_subscription_screen.dart';
import '../subscription/paywall_screen.dart';
import 'notification_settings_screen.dart';
import 'referral_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                padding: const EdgeInsets.fromLTRB(
                    Insets.x4, 0, Insets.x4, 14),
                child: Row(
                  children: [
                    SquareIconButton(Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop()),
                    Expanded(
                      child: Text('Settings',
                          textAlign: TextAlign.center,
                          style: AppText.h3.copyWith(fontSize: 16)),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
              ),

              _Section('Account'),
              _Row(Icons.person_outline_rounded, 'Edit profile',
                  onTap: () => _push(context, const EditProfileScreen())),
              _Row(Icons.alternate_email_rounded, 'Email & phone',
                  trailing: 'dotnettashkent@gmail.com'),
              _Row(Icons.lock_outline_rounded, 'Password & security'),

              _Section('Premium'),
              _Row(
                s.isPremium ? Icons.workspace_premium : Icons.workspace_premium_outlined,
                'Subscription',
                trailing: s.isPremium ? 'Active' : 'Free',
                trailingColor: s.isPremium ? AppColors.gold : AppColors.sText3,
                onTap: () => _push(
                    context,
                    s.isPremium
                        ? const ManageSubscriptionScreen()
                        : const PaywallScreen()),
              ),
              _Row(Icons.card_giftcard_rounded, 'Invite friends · earn premium',
                  trailing: '+${AppState.referralRewardDays}d each',
                  trailingColor: AppColors.success,
                  onTap: () => _push(context, const ReferralScreen())),

              _Section('Notifications'),
              _Row(Icons.notifications_none_rounded, 'Notification settings',
                  onTap: () =>
                      _push(context, const NotificationSettingsScreen())),

              _Section('Preferences'),
              _Row(Icons.straighten_rounded, 'Distance unit', trailing: 'km'),

              _Section('Privacy'),
              _Row(Icons.block_rounded, 'Blocked users'),
              _Row(Icons.visibility_off_outlined, 'Who can call me',
                  trailing: 'Everyone'),
              _ToggleRow(Icons.location_on_outlined, 'Show me on the map',
                  value: true, onChanged: (_) {}),

              _Section('Support'),
              _Row(Icons.help_outline_rounded, 'Help center'),
              _Row(Icons.description_outlined, 'Terms of Service'),
              _Row(Icons.privacy_tip_outlined, 'Privacy Policy'),
              _Row(Icons.info_outline_rounded, 'About Speek',
                  trailing: 'v1.0.0'),

              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
                child: GhostButton('Log out',
                    onTap: () => Navigator.of(context).pop()),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text('Made with 💜 for the world',
                    style: AppText.caption.copyWith(fontSize: 11)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(Insets.x5, 22, Insets.x5, 8),
        child: Text(title.toUpperCase(),
            style: AppText.label.copyWith(
                color: AppColors.sText3,
                fontSize: 12,
                letterSpacing: 0.5)),
      );
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailing;
  final Color? trailingColor;
  final VoidCallback? onTap;
  const _Row(this.icon, this.label,
      {this.trailing, this.trailingColor, this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Insets.x5, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 21, color: AppColors.sText2),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: AppText.body)),
            if (trailing != null)
              Text(trailing!,
                  style: AppText.caption.copyWith(
                      color: trailingColor ?? AppColors.sText3, fontSize: 13)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: AppColors.sText3, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(this.icon, this.label,
      {required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Insets.x5, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 21, color: AppColors.sText2),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: AppText.body)),
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
