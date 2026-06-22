import 'package:flutter/material.dart';

import '../../services/purchase_service.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../subscription/paywall_screen.dart';
import 'trial_started_screen.dart';

/// The "wow" reveal shown right after a user picks their goals. For each chosen
/// goal it animates a personalized **A → B** journey on a glowing timeline:
/// where they are today (muted point A) and the vibrant result they'll reach in
/// 1–2 months with a small daily habit (point B). This is the retention hook —
/// the user sees the payoff before committing.
class GoalJourneyScreen extends StatefulWidget {
  const GoalJourneyScreen({super.key});

  @override
  State<GoalJourneyScreen> createState() => _GoalJourneyScreenState();
}

class _GoalJourneyScreenState extends State<GoalJourneyScreen> {
  final _page = PageController();
  int _index = 0;
  bool _busy = false;

  late final List<_Journey> _journeys = _buildJourneys();

  List<_Journey> _buildJourneys() {
    final s = AppState.instance;
    final goals = s.onboardingGoals.toList()..sort();
    final level = s.level.isNotEmpty ? s.level : 'B1';
    final next = _nextLevel(level);

    _Journey forGoal(int g) {
      switch (g) {
        case 1: // Network
          return _Journey(
            emoji: '🤝',
            tint: AppColors.cyan,
            kicker: 'NETWORK',
            title: 'Build your\nglobal network',
            aTag: 'Solo',
            aTitle: 'Today',
            aSub: 'A few contacts, all in one timezone.',
            steps: const [
              ('🌐', 'Week 1', 'Meet your first 5 speakers worldwide'),
              ('🔁', 'Week 2–3', 'Turn chats into weekly calls'),
              ('⭐', 'Week 4', 'Join culture circles & group talks'),
            ],
            bTag: 'Global',
            bTitle: 'In 1–2 months',
            bResult: 'A worldwide circle of friends & professionals you actually talk to.',
            habit: '2–3 conversations a week',
          );
        case 2: // Explore cultures
          return _Journey(
            emoji: '🌍',
            tint: AppColors.gold,
            kicker: 'EXPLORE',
            title: 'Explore the\nreal world',
            aTag: 'Bubble',
            aTitle: 'Today',
            aSub: 'The world seen through a screen.',
            steps: const [
              ('🗺', 'Week 1', 'Talk to people from 3 new countries'),
              ('💬', 'Week 2–3', 'Pick up real slang, customs & stories'),
              ('🏅', 'Week 4', 'Unlock your first country badges'),
            ],
            bTag: 'Worldly',
            bTitle: 'In 1–2 months',
            bResult: 'Friends across continents and a passport full of cultures.',
            habit: '10–15 min a day',
          );
        default: // Speaking
          return _Journey(
            emoji: '🚀',
            tint: AppColors.brand400,
            kicker: 'SPEAKING',
            title: 'Speak English\nwith confidence',
            aTag: level,
            aTitle: 'Today · $level',
            aSub: 'You hesitate, translate in your head, freeze on calls.',
            steps: const [
              ('🎙', 'Week 1', 'Daily 10–15 min real conversations'),
              ('⚡', 'Week 2–3', 'Think in English — fewer pauses'),
              ('📞', 'Week 4', 'Hold a 10-min call with a native'),
            ],
            bTag: next,
            bTitle: 'In 1–2 months · $next',
            bResult: 'You speak smoothly and level up from $level to $next.',
            habit: '10–15 min a day',
          );
      }
    }

    return goals.map(forGoal).toList();
  }

  static String _nextLevel(String level) {
    const cefr = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'Fluent'];
    final i = cefr.indexOf(level);
    if (i < 0) return 'B2';
    return cefr[(i + 1).clamp(0, cefr.length - 1)];
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    await AppState.instance.submitOnboarding();

    final res = await PurchaseService.instance.buy(yearly: false);
    if (!mounted) return;
    if (res.ok) {
      AppState.instance.startTrial();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TrialStartedScreen()),
        (_) => false,
      );
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PaywallScreen()));
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multi = _journeys.length > 1;
    final tint = _journeys[_index].tint;
    return Scaffold(
      backgroundColor: AppColors.n900,
      body: Stack(
        children: [
          // Ambient glow that shifts to the active journey's colour.
          Positioned(
            top: -120,
            left: -60,
            right: -60,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  tint.withValues(alpha: 0.28),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(Insets.x6, 16, Insets.x6, 4),
                  child: Column(
                    children: [
                      Pill(multi
                          ? '✨ Your ${_journeys.length} journeys'
                          : '✨ Your journey'),
                      const SizedBox(height: 12),
                      Text('Here\'s where Speek takes you',
                          textAlign: TextAlign.center,
                          style: AppText.h1.copyWith(fontSize: 25, height: 1.1)),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    itemCount: _journeys.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) =>
                        _JourneyView(key: ValueKey(i), journey: _journeys[i]),
                  ),
                ),
                if (multi) ...[
                  const SizedBox(height: 4),
                  Dots(count: _journeys.length, index: _index),
                ],
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Insets.x6, 12, Insets.x6, Insets.x6),
                  child: Column(
                    children: [
                      PrimaryButton(
                        _busy ? 'Starting…' : 'Start my 14-day journey 🚀',
                        onTap: _busy ? null : _start,
                      ),
                      const SizedBox(height: 8),
                      Text('Full access free for 14 days · cancel anytime',
                          style:
                              AppText.caption.copyWith(color: AppColors.n300)),
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

class _Journey {
  final String emoji;
  final Color tint;
  final String kicker;
  final String title;
  final String aTag;
  final String aTitle;
  final String aSub;
  final List<(String, String, String)> steps; // emoji, when, what
  final String bTag;
  final String bTitle;
  final String bResult;
  final String habit;
  const _Journey({
    required this.emoji,
    required this.tint,
    required this.kicker,
    required this.title,
    required this.aTag,
    required this.aTitle,
    required this.aSub,
    required this.steps,
    required this.bTag,
    required this.bTitle,
    required this.bResult,
    required this.habit,
  });
}

/// One journey: glowing timeline with a staggered entrance + a pulsing payoff.
class _JourneyView extends StatefulWidget {
  final _Journey journey;
  const _JourneyView({super.key, required this.journey});

  @override
  State<_JourneyView> createState() => _JourneyViewState();
}

class _JourneyViewState extends State<_JourneyView>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..forward();
  late final AnimationController _pulse = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2200))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _intro.dispose();
    _pulse.dispose();
    super.dispose();
  }

  Widget _staggered(int order, int total, Widget child) {
    final start = (order / (total + 1)).clamp(0.0, 0.95);
    final end = ((order + 1.6) / (total + 1)).clamp(0.05, 1.0);
    final anim = CurvedAnimation(
        parent: _intro,
        curve: Interval(start, end, curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: anim,
      builder: (_, c) => Opacity(
        opacity: anim.value,
        child: Transform.translate(
            offset: Offset(0, (1 - anim.value) * 22), child: c),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.journey;
    final total = j.steps.length + 3;
    var order = 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.x5, 8, Insets.x5, 8),
      children: [
        _staggered(order++, total, _hero(j)),
        const SizedBox(height: 22),
        // Timeline
        _staggered(order++, total,
            _entry(j, isLast: false, dot: _letterDot(j, 'A'), card: _aCard(j))),
        for (int i = 0; i < j.steps.length; i++)
          _staggered(
              order++,
              total,
              _entry(j,
                  isLast: false,
                  dot: _stepDot(j),
                  card: _stepCard(j, j.steps[i]))),
        _staggered(order++, total,
            _entry(j, isLast: true, dot: _letterDot(j, 'B', glow: true), card: _bCard(j))),
      ],
    );
  }

  // ---- Hero ----
  Widget _hero(_Journey j) => Column(
        children: [
          SizedBox(
            width: 116,
            height: 116,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) {
                final t = _pulse.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96 + t * 18,
                      height: 96 + t * 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: j.tint.withValues(alpha: 0.35 * (1 - t)),
                            width: 1.5),
                      ),
                    ),
                    child!,
                  ],
                );
              },
              child: Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [j.tint, j.tint.withValues(alpha: 0.5)],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: j.tint.withValues(alpha: 0.55),
                        blurRadius: 38,
                        offset: const Offset(0, 14)),
                  ],
                ),
                child: Text(j.emoji, style: const TextStyle(fontSize: 44)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(j.kicker,
              style: AppText.label.copyWith(
                  color: j.tint,
                  letterSpacing: 3,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(j.title,
              textAlign: TextAlign.center,
              style: AppText.displayMd.copyWith(fontSize: 25, height: 1.12)),
          const SizedBox(height: 14),
          _routeChip(j),
        ],
      );

  /// "B1 → B2" style transformation chip under the title.
  Widget _routeChip(_Journey j) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _routeTag(j.aTag, AppColors.n300, Colors.white.withValues(alpha: 0.06)),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 16, color: j.tint),
            const SizedBox(width: 8),
            _routeTag(j.bTag, Colors.white, j.tint),
          ],
        ),
      );

  Widget _routeTag(String text, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
        child: Text(text,
            style: AppText.label.copyWith(color: fg, fontSize: 13)),
      );

  // ---- Timeline plumbing ----
  Widget _entry(_Journey j,
          {required bool isLast,
          required Widget dot,
          required Widget card}) =>
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 44,
              child: Column(
                children: [
                  dot,
                  if (!isLast)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 3,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                j.tint.withValues(alpha: 0.6),
                                j.tint.withValues(alpha: 0.25),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                  color: j.tint.withValues(alpha: 0.35),
                                  blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: card,
              ),
            ),
          ],
        ),
      );

  Widget _letterDot(_Journey j, String letter, {bool glow = false}) => Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: glow
              ? LinearGradient(colors: [j.tint, j.tint.withValues(alpha: 0.6)])
              : null,
          color: glow ? null : AppColors.n800,
          border: Border.all(color: j.tint.withValues(alpha: 0.7), width: 2),
          boxShadow: glow
              ? [BoxShadow(color: j.tint.withValues(alpha: 0.6), blurRadius: 18)]
              : null,
        ),
        child: Text(letter,
            style: AppText.h3.copyWith(
                color: glow ? Colors.white : j.tint, fontSize: 16)),
      );

  Widget _stepDot(_Journey j) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Center(
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: j.tint,
              border: Border.all(color: AppColors.n900, width: 3),
              boxShadow: [
                BoxShadow(color: j.tint.withValues(alpha: 0.6), blurRadius: 10),
              ],
            ),
          ),
        ),
      );

  // ---- Cards ----

  /// Gradient-bordered glass card (the "powerful border" look).
  Widget _bordered({
    required Widget child,
    required Gradient border,
    Color? fill,
    Gradient? fillGradient,
    List<BoxShadow>? glow,
    double radius = 20,
  }) =>
      Container(
        decoration: BoxDecoration(
          gradient: border,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: glow,
        ),
        padding: const EdgeInsets.all(1.4),
        child: Container(
          decoration: BoxDecoration(
            color: fill ?? const Color(0xFF121019),
            gradient: fillGradient,
            borderRadius: BorderRadius.circular(radius - 1.4),
          ),
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );

  Widget _aCard(_Journey j) => _bordered(
        border: LinearGradient(colors: [
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.05),
        ]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('POINT A · ${j.aTitle.toUpperCase()}',
                      style: AppText.caption.copyWith(
                          color: AppColors.n300,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          fontSize: 11)),
                  const SizedBox(height: 6),
                  Text(j.aSub,
                      style: AppText.body
                          .copyWith(color: AppColors.n100, fontSize: 14.5)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('You are here',
                  style: AppText.caption
                      .copyWith(color: AppColors.n200, fontSize: 11)),
            ),
          ],
        ),
      );

  Widget _stepCard(_Journey j, (String, String, String) s) => _bordered(
        radius: 16,
        border: LinearGradient(colors: [
          j.tint.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0.05),
        ]),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    j.tint.withValues(alpha: 0.25),
                    j.tint.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: j.tint.withValues(alpha: 0.4)),
              ),
              child: Text(s.$1, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.$2.toUpperCase(),
                      style: AppText.caption.copyWith(
                          color: j.tint,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          fontSize: 11)),
                  const SizedBox(height: 3),
                  Text(s.$3,
                      style: AppText.body
                          .copyWith(fontSize: 14.5, height: 1.25)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _bCard(_Journey j) => AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) {
          final t = _pulse.value;
          return _bordered(
            radius: 22,
            border: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [j.tint, Colors.white.withValues(alpha: 0.25)],
            ),
            fillGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                j.tint.withValues(alpha: 0.30),
                j.tint.withValues(alpha: 0.08),
              ],
            ),
            glow: [
              BoxShadow(
                  color: j.tint.withValues(alpha: 0.25 + t * 0.25),
                  blurRadius: 26 + t * 16,
                  offset: const Offset(0, 12)),
            ],
            child: child!,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('🎯',
                    style: TextStyle(fontSize: 16, color: AppColors.gold)),
                const SizedBox(width: 6),
                Text('POINT B · ${j.bTitle.toUpperCase()}',
                    style: AppText.caption.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        fontSize: 11)),
              ],
            ),
            const SizedBox(height: 10),
            Text(j.bResult,
                style: AppText.h3.copyWith(
                    fontSize: 17, height: 1.35, color: Colors.white)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded,
                      color: AppColors.gold, size: 18),
                  const SizedBox(width: 8),
                  Text('All it takes: ${j.habit}',
                      style: AppText.label.copyWith(
                          color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      );
}
