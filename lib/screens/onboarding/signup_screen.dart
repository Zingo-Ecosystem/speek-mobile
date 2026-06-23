import 'package:flutter/material.dart';

import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_buttons.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../../widgets/invite_code_field.dart';
import '../shell.dart';
import 'create_account_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Rebuild so AuthButtons always receives the latest typed code.
    _codeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BrandGlow(opacity: 0.7),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      const LogoMark(),
                      const SizedBox(height: 18),
                      Text('Welcome to Speek',
                          textAlign: TextAlign.center,
                          style: AppText.displayMd),
                      const SizedBox(height: 8),
                      Text('Create your free account in seconds.',
                          textAlign: TextAlign.center, style: AppText.bodyMuted),
                      const Spacer(flex: 4),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            Insets.x6, 0, Insets.x6, Insets.x8),
                        child: Column(
                          children: [
                            InviteCodeField(controller: _codeCtrl),
                            const SizedBox(height: 14),
                            AuthButtons(
                              referralCode:
                                  InviteCodeField.readCode(_codeCtrl),
                              onAuthenticated: (needsOnboarding) {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => needsOnboarding
                                        ? const CreateAccountScreen()
                                        : const ShellScreen(initialIndex: 2),
                                  ),
                                  (_) => false,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            const LegalNote(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
