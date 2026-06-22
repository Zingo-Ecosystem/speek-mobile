import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_exception.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'snack.dart';

/// Two-step passwordless email login: enter email → enter the 6-digit code.
/// Returns the [AuthResult] on success, or null if dismissed.
Future<AuthResult?> showEmailAuthSheet(BuildContext context,
    {String? referralCode}) {
  return showModalBottomSheet<AuthResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _EmailAuthSheet(referralCode: referralCode),
    ),
  );
}

class _EmailAuthSheet extends StatefulWidget {
  final String? referralCode;
  const _EmailAuthSheet({this.referralCode});

  @override
  State<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<_EmailAuthSheet> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains('@') || !email.contains('.')) {
      showSnack(context, 'Enter a valid email address.', type: SnackType.error);
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService.instance.requestEmailCode(email);
      if (mounted) setState(() => _codeSent = true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, type: SnackType.error);
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not send the code. Try again.',
            type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.length < 4) {
      showSnack(context, 'Enter the code we sent you.', type: SnackType.error);
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await AuthService.instance.verifyEmailCode(
        _email.text.trim(),
        code,
        referralCode: widget.referralCode,
      );
      if (mounted) Navigator.of(context).pop(res);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, type: SnackType.error);
    } catch (_) {
      if (mounted) {
        showSnack(context, 'Could not verify the code.', type: SnackType.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.n800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0x4D6C63FF))),
      ),
      padding: const EdgeInsets.fromLTRB(Insets.x5, 14, Insets.x5, Insets.x6),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 18),
            Text(_codeSent ? 'Enter your code' : 'Continue with email',
                style: AppText.h2),
            const SizedBox(height: 6),
            Text(
                _codeSent
                    ? 'We sent a 6-digit code to ${_email.text.trim()}.'
                    : 'We\'ll email you a one-time code — no password needed.',
                style: AppText.smMuted),
            const SizedBox(height: 18),
            if (!_codeSent) ...[
              _field(
                controller: _email,
                hint: 'you@example.com',
                icon: Icons.alternate_email_rounded,
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              PrimaryButton(_busy ? 'Sending…' : 'Send code',
                  onTap: _busy ? null : _sendCode),
            ] else ...[
              _field(
                controller: _code,
                hint: '• • • • • •',
                icon: Icons.lock_outline_rounded,
                keyboard: TextInputType.number,
                maxLength: 6,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              PrimaryButton(_busy ? 'Verifying…' : 'Verify & continue',
                  onTap: _busy ? null : _verify),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: _busy ? null : _sendCode,
                  child: Text('Resend code',
                      style: AppText.body.copyWith(color: AppColors.brand300)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
    int? maxLength,
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLength: maxLength,
      inputFormatters: formatters,
      autofocus: true,
      style: AppText.body.copyWith(
          letterSpacing: maxLength == 6 ? 6 : 0, fontSize: 16),
      cursorColor: AppColors.brand400,
      decoration: InputDecoration(
        counterText: '',
        prefixIcon: Icon(icon, color: AppColors.n200, size: 20),
        hintText: hint,
        hintStyle: AppText.body.copyWith(color: AppColors.n300),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          borderSide: const BorderSide(color: AppColors.brand400),
        ),
      ),
    );
  }
}
