import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../shell.dart';

class TrialStartedScreen extends StatelessWidget {
  const TrialStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.6),
            radius: 1.1,
            colors: [Color(0xFF1A1A2E), Color(0xFF0A0A0F)],
          ),
        ),
        child: Stack(
          children: [
            const BrandGlow(opacity: 0.5),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const Text('🎉', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 10),
                  Text("You're all set!", style: AppText.h1),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Insets.x6),
                    child: Text(
                        'Your 14-day free trial is active. Talk to the whole world — on us.',
                        textAlign: TextAlign.center,
                        style: AppText.bodyMuted),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Insets.x6),
                    child: _TrialCard(),
                  ),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        Insets.x6, 0, Insets.x6, Insets.x8),
                    child: PrimaryButton('Explore the map 🌍', onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) => const ShellScreen(initialIndex: 1)),
                        (_) => false,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrialCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.brand500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brand500.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Trial ends',
                  style: AppText.label.copyWith(color: AppColors.textSecondary)),
              Text('Jun 28', style: AppText.h3.copyWith(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 8, color: Colors.white.withValues(alpha: 0.1)),
                FractionallySizedBox(
                  widthFactor: 0.08,
                  child: Container(
                    height: 8,
                    decoration:
                        const BoxDecoration(gradient: AppColors.grad),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Day 1 of 14 · then \$15/mo · cancel anytime',
                style: AppText.caption),
          ),
        ],
      ),
    );
  }
}
