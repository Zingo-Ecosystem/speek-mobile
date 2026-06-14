import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'common.dart';

/// Google / Apple sign-in buttons used on sign up and the register gate.
class AuthButtons extends StatelessWidget {
  final VoidCallback onAuth;
  const AuthButtons({super.key, required this.onAuth});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GhostButton('Continue with Google',
            light: true,
            onTap: onAuth,
            leading: const _GoogleG()),
        const SizedBox(height: 12),
        GhostButton('Continue with Apple',
            dark: true,
            onTap: onAuth,
            leading: const Icon(Icons.apple, color: Colors.white, size: 22)),
      ],
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) {
    // Simple multi-color "G" mark.
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: Text('G',
          style: AppText.h3.copyWith(
              color: const Color(0xFF4285F4),
              fontWeight: FontWeight.w800,
              fontSize: 19)),
    );
  }
}

/// Legal footer text with brand-colored Terms / Privacy.
class LegalNote extends StatelessWidget {
  const LegalNote({super.key});
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppText.caption.copyWith(height: 1.5),
        children: [
          const TextSpan(text: 'By continuing you agree to our '),
          TextSpan(
              text: 'Terms',
              style: AppText.caption.copyWith(color: AppColors.brand300)),
          const TextSpan(text: ' & '),
          TextSpan(
              text: 'Privacy',
              style: AppText.caption.copyWith(color: AppColors.brand300)),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
