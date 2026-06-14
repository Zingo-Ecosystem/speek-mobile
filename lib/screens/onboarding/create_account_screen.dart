import 'package:flutter/material.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'trial_started_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _controller = PageController();
  int _step = 0;
  static const _total = 4;

  void _next() {
    if (_step < _total - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      AppState.instance.register();
      AppState.instance.startTrial();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TrialStartedScreen()));
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      _controller.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _step == _total - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Insets.x4, Insets.x4, Insets.x4, 14),
              child: Row(
                children: [
                  SquareIconButton(Icons.arrow_back, onTap: _back),
                  Expanded(
                    child: Text('Step ${_step + 1} of $_total',
                        textAlign: TextAlign.center, style: AppText.h3.copyWith(fontSize: 15)),
                  ),
                  if (_step == 0)
                    TextButton(
                      onPressed: _next,
                      child: Text('Skip',
                          style: AppText.label.copyWith(color: AppColors.brand300)),
                    )
                  else
                    const SizedBox(width: 42),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.x6),
              child: _ProgressBar(value: (_step + 1) / _total),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: const [
                  _PhotosStep(),
                  _BasicsStep(),
                  _InterestsStep(),
                  _GoalsStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Insets.x6, Insets.x2, Insets.x6, Insets.x8),
              child: PrimaryButton(last ? 'Start exploring 🚀' : 'Continue',
                  onTap: _next),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Stack(
        children: [
          Container(height: 5, color: Colors.white.withValues(alpha: 0.08)),
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 300),
            widthFactor: value,
            child: Container(
              height: 5,
              decoration: const BoxDecoration(gradient: AppColors.grad),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Step 1: Photos ----
class _PhotosStep extends StatelessWidget {
  const _PhotosStep();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.x6, Insets.x5, Insets.x6, Insets.x6),
      children: [
        Text('Add your best photos', style: AppText.h2),
        const SizedBox(height: 6),
        _muted(context, 'Profiles with 3+ photos get ', '5× more', ' conversations.'),
        const SizedBox(height: 18),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _photo(
                'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=500&q=80',
                main: true),
            _photo(
                'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=400&q=80'),
            _addTile(),
            _addTile(),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: _addTile())]),
      ],
    );
  }

  Widget _photo(String url, {bool main = false}) => Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(url, fit: BoxFit.cover),
            ),
          ),
          if (main)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    gradient: AppColors.grad,
                    borderRadius: BorderRadius.circular(6)),
                child: Text('MAIN',
                    style: AppText.caption.copyWith(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      );

  Widget _addTile() => Container(
        decoration: BoxDecoration(
          color: AppColors.brand500.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppColors.brand500.withValues(alpha: 0.4),
              width: 2,
              style: BorderStyle.solid),
        ),
        child: const Center(
            child: Icon(Icons.add, color: AppColors.brand400, size: 30)),
      );
}

// ---- Step 2: Basics ----
class _BasicsStep extends StatefulWidget {
  const _BasicsStep();
  @override
  State<_BasicsStep> createState() => _BasicsStepState();
}

class _BasicsStepState extends State<_BasicsStep> {
  int _role = 0; // 0 learner, 1 native
  String _level = 'B1';
  String _gender = 'Female';
  String _country = '🇫🇷 France';

  static const _genders = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];
  static const _countries = [
    '🇫🇷 France', '🇺🇸 USA', '🇬🇧 UK', '🇪🇸 Spain', '🇩🇪 Germany',
    '🇧🇷 Brazil', '🇯🇵 Japan', '🇰🇷 Korea', '🇮🇳 India', '🇺🇿 Uzbekistan',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.x6, Insets.x5, Insets.x6, Insets.x6),
      children: [
        Text('The basics', style: AppText.h2),
        const SizedBox(height: 6),
        Text('This helps us match you with the right people.',
            style: AppText.smMuted),
        const SizedBox(height: 18),
        const _Field(label: 'First name', value: 'Chloe'),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: _Field(label: 'Age', value: '24')),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _Field(
                label: 'Gender',
                value: _gender,
                dropdown: true,
                onTap: () async {
                  final v = await pickOption(context,
                      title: 'Gender',
                      options: _genders,
                      selected: _gender);
                  if (v != null) setState(() => _gender = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Label('I am a…'),
        const SizedBox(height: 8),
        Row(
          children: [
            _seg('🎓 Learner', _role == 0, () => setState(() => _role = 0)),
            const SizedBox(width: 10),
            _seg('🎙 Native', _role == 1, () => setState(() => _role = 1)),
          ],
        ),
        const SizedBox(height: 16),
        _Label('English level'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final l in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'])
              GestureDetector(
                onTap: () => setState(() => _level = l),
                child: Chip2(l, solid: _level == l),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Country',
          value: _country,
          dropdown: true,
          onTap: () async {
            final v = await pickOption(context,
                title: 'Country', options: _countries, selected: _country);
            if (v != null) setState(() => _country = v);
          },
        ),
      ],
    );
  }

  Widget _seg(String label, bool on, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on
                ? AppColors.brand500.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
                color: on
                    ? AppColors.brand500
                    : Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(label,
              style: AppText.label.copyWith(
                  color: on ? AppColors.brand200 : AppColors.textPrimary)),
        ),
      ),
    );
  }
}

// ---- Step 3: Interests ----
class _InterestsStep extends StatefulWidget {
  const _InterestsStep();
  @override
  State<_InterestsStep> createState() => _InterestsStepState();
}

class _InterestsStepState extends State<_InterestsStep> {
  final _all = const [
    '🎵 Music', '✈️ Travel', '🎮 Gaming', '📚 Books', '🏔 Hiking',
    '🍳 Cooking', '🎬 Movies', '⚽ Sports', '📷 Photography', '☕ Coffee',
    '🎨 Art', '💻 Tech', '🐶 Pets', '🧘 Yoga', '🎤 Karaoke', '🌱 Nature',
  ];
  final _selected = {'🎵 Music', '✈️ Travel', '🎮 Gaming', '🍳 Cooking', '🎬 Movies', '💻 Tech'};

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.x6, Insets.x5, Insets.x6, Insets.x6),
      children: [
        Text('What are you into?', style: AppText.h2),
        const SizedBox(height: 6),
        Text('Pick at least 3 — we match on shared interests.',
            style: AppText.smMuted),
        const SizedBox(height: 18),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final i in _all)
              GestureDetector(
                onTap: () => setState(() =>
                    _selected.contains(i) ? _selected.remove(i) : _selected.add(i)),
                child: Chip2(i, active: _selected.contains(i)),
              ),
          ],
        ),
        const SizedBox(height: 26),
        _Label('Languages you speak'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            Chip2('🇫🇷 French · Native', solid: true),
            Chip2('🇬🇧 English · B1', active: true),
            Chip2('+ Add'),
          ],
        ),
      ],
    );
  }
}

// ---- Step 4: Goals + trial ----
class _GoalsStep extends StatefulWidget {
  const _GoalsStep();
  @override
  State<_GoalsStep> createState() => _GoalsStepState();
}

class _GoalsStepState extends State<_GoalsStep> {
  final _on = {0, 1};
  final _goals = const [
    ('🗣', 'Speaking practice', 'Improve fluency with real talks'),
    ('🤝', 'Friendship', 'Meet people around the world'),
    ('💜', 'Dating', 'Open to something more'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.x6, Insets.x5, Insets.x6, Insets.x6),
      children: [
        Text('What are you looking for?', style: AppText.h2),
        const SizedBox(height: 6),
        Text('Be honest — it shapes who you meet.', style: AppText.smMuted),
        const SizedBox(height: 18),
        for (int i = 0; i < _goals.length; i++) ...[
          _goalTile(i),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppColors.gradGold,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Text('🎁', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: AppText.label.copyWith(
                        color: const Color(0xFF3A2600), height: 1.4),
                    children: const [
                      TextSpan(text: 'Your '),
                      TextSpan(
                          text: '14-day free trial',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      TextSpan(text: ' starts now. Talk unlimited!'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _goalTile(int i) {
    final on = _on.contains(i);
    final g = _goals[i];
    return GestureDetector(
      onTap: () =>
          setState(() => on ? _on.remove(i) : _on.add(i)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: on
              ? AppColors.brand500.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
              color:
                  on ? AppColors.brand500 : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Text(g.$1, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.$2, style: AppText.label),
                  const SizedBox(height: 2),
                  Text(g.$3, style: AppText.caption),
                ],
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? AppColors.brand500 : Colors.transparent,
                border: Border.all(
                    color: on
                        ? AppColors.brand500
                        : Colors.white.withValues(alpha: 0.2),
                    width: 2),
              ),
              child: on
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ---- shared bits ----
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppText.label.copyWith(color: AppColors.textSecondary));
}

class _Field extends StatelessWidget {
  final String label;
  final String value;
  final bool dropdown;
  final VoidCallback? onTap;
  const _Field(
      {required this.label,
      required this.value,
      this.dropdown = false,
      this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Expanded(child: Text(value, style: AppText.body)),
                if (dropdown)
                  const Icon(Icons.keyboard_arrow_down, color: AppColors.n300),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _muted(BuildContext context, String a, String bold, String b) {
  return Text.rich(
    TextSpan(
      style: AppText.smMuted,
      children: [
        TextSpan(text: a),
        TextSpan(
            text: bold,
            style: AppText.smMuted.copyWith(
                color: AppColors.brand300, fontWeight: FontWeight.w700)),
        TextSpan(text: b),
      ],
    ),
  );
}
