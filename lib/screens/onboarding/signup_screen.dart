import 'package:flutter/material.dart';

import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_buttons.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../shell.dart';
import 'create_account_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const BrandGlow(opacity: 0.7),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                const LogoMark(),
                const SizedBox(height: 18),
                Text('Welcome to Speek',
                    textAlign: TextAlign.center, style: AppText.displayMd),
                const SizedBox(height: 8),
                Text('Create your free account in seconds.',
                    textAlign: TextAlign.center, style: AppText.bodyMuted),
                const Spacer(flex: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Insets.x6, 0, Insets.x6, Insets.x8),
                  child: Column(
                    children: [
                      AuthButtons(
                        onAuthenticated: (needsOnboarding) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => needsOnboarding
                                  ? const CreateAccountScreen()
                                  : const ShellScreen(initialIndex: 1),
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
        ],
      ),
    );
  }
}
