import 'dart:async';

import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import '../shell.dart';
import 'create_account_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..forward();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Try to restore a session while the splash animation plays.
    final results = await Future.wait([
      AppState.instance.bootstrap(),
      Future.delayed(const Duration(milliseconds: 1600)),
    ]);
    if (!mounted) return;
    final authed = results.first as bool;

    Widget next;
    if (authed) {
      next = AppState.instance.isOnboarded
          ? const ShellScreen(initialIndex: 1)
          : const CreateAccountScreen();
    } else {
      next = const OnboardingScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, a, __) => next,
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    final scale = Tween(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradDeep),
        child: Stack(
          children: [
            const BrandGlow(opacity: 0.5),
            Center(
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const LogoMark(size: 96),
                      const SizedBox(height: 22),
                      const Wordmark(fontSize: 46),
                      const SizedBox(height: 10),
                      Text('Speak the world.',
                          style: AppText.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.8))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
