import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_buttons.dart';
import '../../widgets/invite_code_field.dart';
import '../shell.dart';
import '../onboarding/create_account_screen.dart';

/// Soft-wall shown when a guest taps Call/Message before registering.
Future<void> showRegisterGate(BuildContext context, SpeekUser user) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => _RegisterGateSheet(user: user),
  );
}

class _RegisterGateSheet extends StatefulWidget {
  final SpeekUser user;
  const _RegisterGateSheet({required this.user});

  @override
  State<_RegisterGateSheet> createState() => _RegisterGateSheetState();
}

class _RegisterGateSheetState extends State<_RegisterGateSheet> {
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _codeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.n800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Color(0x4D6C63FF))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(Insets.x6, 14, Insets.x6,
              Insets.x6 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 22),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.brand500.withValues(alpha: 0.16),
                ),
                child: const Center(
                    child: Text('🔒', style: TextStyle(fontSize: 30))),
              ),
              const SizedBox(height: 16),
              Text('Create an account to call',
                  textAlign: TextAlign.center, style: AppText.h2),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  style: AppText.bodyMuted,
                  children: [
                    TextSpan(
                        text:
                            'Sign up free to talk live with ${user.name} and thousands worldwide. '),
                    TextSpan(
                        text: '14 days free.',
                        style: AppText.bodyMuted.copyWith(
                            color: AppColors.brand300,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              InviteCodeField(controller: _codeCtrl),
              const SizedBox(height: 14),
              AuthButtons(
                referralCode: InviteCodeField.readCode(_codeCtrl),
                onAuthenticated: (needsOnboarding) {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => needsOnboarding
                          ? const CreateAccountScreen()
                          : const ShellScreen(initialIndex: 2)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
