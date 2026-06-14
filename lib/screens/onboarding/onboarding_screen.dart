import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'signup_screen.dart';

class _Slide {
  final String pill;
  final String title;
  final String body;
  final Widget hero;
  const _Slide(this.pill, this.title, this.body, this.hero);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  late final _slides = <_Slide>[
    const _Slide(
      '🌍 A world of speakers',
      'Find people to\ntalk to on the map',
      'Discover real people online right now, from every corner of the planet.',
      _MapHero(),
    ),
    const _Slide(
      '💜 Win-win matching',
      'Match like a\ndating app',
      'Natives find friends. Learners find practice. Everyone wins.',
      _MatchHero(),
    ),
    const _Slide(
      '🏆 Gamified progress',
      'Earn badges as\nyou speak',
      'Streaks, levels and creative badges keep you talking every day.',
      _BadgeHero(),
    ),
  ];

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    } else {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SignupScreen()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return Column(
                    children: [
                      Expanded(flex: 52, child: s.hero),
                      const SizedBox(height: 26),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: Insets.x6),
                        child: Column(
                          children: [
                            Pill(s.pill),
                            const SizedBox(height: 18),
                            Text(s.title,
                                textAlign: TextAlign.center, style: AppText.h1),
                            const SizedBox(height: 12),
                            Text(s.body,
                                textAlign: TextAlign.center,
                                style: AppText.bodyMuted),
                          ],
                        ),
                      ),
                      const Spacer(),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.x6, 0, Insets.x6, Insets.x8),
              child: Column(
                children: [
                  Dots(count: _slides.length, index: _index),
                  const SizedBox(height: 18),
                  PrimaryButton(last ? 'Get started' : 'Continue', onTap: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Hero illustrations ----

class _MapHero extends StatelessWidget {
  const _MapHero();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1,
          colors: [Color(0xFF1A1A2E), Color(0xFF0C0C14)],
        ),
      ),
      child: Stack(
        children: const [
          BrandGlow(),
          Positioned(left: 50, top: 60, child: Avatar(_a1, size: 54, ringColor: AppColors.brand500, borderWidth: 2, borderColor: AppColors.brand500)),
          Positioned(right: 60, top: 40, child: Avatar(_a2, size: 46, borderWidth: 2)),
          Positioned(left: 90, bottom: 50, child: Avatar(_a3, size: 48, borderWidth: 2)),
          Positioned(right: 80, bottom: 80, child: Avatar(_a4, size: 42, borderWidth: 2)),
        ],
      ),
    );
  }
}

class _MatchHero extends StatelessWidget {
  const _MatchHero();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1,
          colors: [Color(0xFF201A3A), Color(0xFF0C0C14)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const BrandGlow(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: const Offset(12, 0),
                child: Transform.rotate(angle: -0.1, child: _card(_a3)),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.grad,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.brand500.withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 14))
                  ],
                ),
                child: const Icon(Icons.favorite_rounded,
                    color: Colors.white, size: 30),
              ),
              Transform.translate(
                offset: const Offset(-12, 0),
                child: Transform.rotate(angle: 0.1, child: _card(_a2)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(String url) => Container(
        width: 96,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.n500, width: 3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Image.network(url, fit: BoxFit.cover),
        ),
      );
}

class _BadgeHero extends StatelessWidget {
  const _BadgeHero();
  @override
  Widget build(BuildContext context) {
    const items = [
      ('🔥', AppColors.warning),
      ('🌍', AppColors.brand500),
      ('🎙', AppColors.success),
      ('💬', AppColors.like),
      ('⭐', AppColors.cyan),
      ('🏆', AppColors.gold),
    ];
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1,
          colors: [Color(0xFF1A1A2E), Color(0xFF0C0C14)],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const BrandGlow(),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            padding: const EdgeInsets.symmetric(horizontal: 60),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final (emoji, c) in items)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.withValues(alpha: 0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: c.withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 8))
                    ],
                  ),
                  child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 28))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

const _a1 =
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=200&q=80';
const _a2 =
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80';
const _a3 =
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80';
const _a4 =
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80';
