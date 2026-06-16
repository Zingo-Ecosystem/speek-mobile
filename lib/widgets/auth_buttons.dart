import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'common.dart';
import 'snack.dart';

/// Google / Apple sign-in buttons. They run the real social-login flow against
/// the backend, store the JWT, hydrate [AppState], then call [onAuthenticated]
/// with whether the account is brand-new (so the caller can route to onboarding
/// vs. the app shell).
class AuthButtons extends StatefulWidget {
  /// Called after a successful login. `isNewUser` is true for first-time
  /// sign-ups (route them through onboarding).
  final void Function(bool isNewUser)? onAuthenticated;

  /// Legacy hook: if provided and no [onAuthenticated], it's called on success.
  final VoidCallback? onAuth;

  final String? referralCode;

  const AuthButtons({super.key, this.onAuthenticated, this.onAuth, this.referralCode});

  @override
  State<AuthButtons> createState() => _AuthButtonsState();
}

class _AuthButtonsState extends State<AuthButtons> {
  bool _busy = false;

  Future<void> _run(Future<AuthResult> Function() signIn) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final res = await signIn();
      await AppState.instance.applyAuth(res);
      if (!mounted) return;
      if (widget.onAuthenticated != null) {
        widget.onAuthenticated!(res.isNewUser || !res.user.isOnboarded);
      } else {
        widget.onAuth?.call();
      }
    } on ApiException catch (e) {
      if (mounted && e.code != 'cancelled') {
        showSnack(context, e.message, type: SnackType.error);
      }
    } catch (e) {
      if (mounted) {
        showSnack(context, 'Sign-in failed. Please try again.',
            type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          children: [
            GhostButton('Continue with Google',
                light: true,
                onTap: _busy
                    ? null
                    : () => _run(() => AuthService.instance
                        .signInWithGoogle(referralCode: widget.referralCode)),
                leading: const _GoogleG()),
            const SizedBox(height: 12),
            GhostButton('Continue with Apple',
                dark: true,
                onTap: _busy
                    ? null
                    : () => _run(() => AuthService.instance
                        .signInWithApple(referralCode: widget.referralCode)),
                leading: const Icon(Icons.apple, color: Colors.white, size: 22)),
          ],
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x66000000),
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: AppColors.brand400),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) {
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
