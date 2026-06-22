import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/snack.dart';
import 'goal_journey_screen.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _controller = PageController();
  int _step = 0;
  static const _total = 4;

  Future<void> _next() async {
    // Require at least one uploaded photo before leaving the photos step.
    if (_step == 0 && AppState.instance.onboardingPhotoUrls.isEmpty) {
      showSnack(context, 'Please add at least one photo to continue.',
          type: SnackType.error);
      return;
    }
    if (_step < _total - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      return;
    }
    if (AppState.instance.onboardingGoals.isEmpty) {
      showSnack(context, 'Pick at least one goal to continue.',
          type: SnackType.error);
      return;
    }
    // Reveal the personalized A→Z journey for the chosen goals. The journey
    // screen finalizes onboarding + the trial when the user commits.
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const GoalJourneyScreen()));
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

// ---- Step 1: Photos (real upload, at least 1 required) ----
class _PhotosStep extends StatefulWidget {
  const _PhotosStep();
  @override
  State<_PhotosStep> createState() => _PhotosStepState();
}

class _PhotosStepState extends State<_PhotosStep> {
  List<String> get _urls => AppState.instance.onboardingPhotoUrls;
  final _busy = <int>{}; // slot indexes currently uploading
  static const _slots = 4;

  Future<void> _pick(int slot) async {
    if (_busy.contains(slot)) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _busy.add(slot));
      final bytes = await picked.readAsBytes();
      final url = await AppState.instance
          .uploadOnboardingPhoto(bytes, picked.name);
      if (!mounted) return;
      setState(() {
        _busy.remove(slot);
        if (url.isNotEmpty) _urls.add(url);
      });
    } catch (e) {
      if (mounted) {
        setState(() => _busy.remove(slot));
        showSnack(context, 'Upload failed: $e', type: SnackType.error);
      }
    }
  }

  void _remove(int index) => setState(() => _urls.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.x6, Insets.x5, Insets.x6, Insets.x6),
      children: [
        Text('Add your best photos', style: AppText.h2),
        const SizedBox(height: 6),
        _muted(context, 'Add at least ', '1 photo', ' — the first is your main.'),
        const SizedBox(height: 18),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            for (int i = 0; i < _slots; i++)
              if (i < _urls.length)
                _photo(i)
              else
                _addTile(i, uploading: _busy.contains(i)),
          ],
        ),
      ],
    );
  }

  Widget _photo(int index) => Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(_urls[index], fit: BoxFit.cover),
            ),
          ),
          if (index == 0)
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
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _remove(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      );

  Widget _addTile(int slot, {bool uploading = false}) => GestureDetector(
        onTap: uploading ? null : () => _pick(slot),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.brand500.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: AppColors.brand500.withValues(alpha: 0.4),
                width: 2,
                style: BorderStyle.solid),
          ),
          child: Center(
            child: uploading
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.brand400))
                : const Icon(Icons.add, color: AppColors.brand400, size: 30),
          ),
        ),
      );
}

// ---- Step 2: Basics ----
class _BasicsStep extends StatefulWidget {
  const _BasicsStep();
  @override
  State<_BasicsStep> createState() => _BasicsStepState();
}

class _BasicsStepState extends State<_BasicsStep> {
  final _s = AppState.instance;
  late final _name = TextEditingController(text: _s.name == 'Speeker' ? '' : _s.name);
  late final _age = TextEditingController(text: _s.age > 0 ? '${_s.age}' : '');
  late int _role = _s.isLearner ? 0 : 1;
  late String _level = _s.level.isNotEmpty ? _s.level : 'B1';
  late String _gender = _s.gender;
  late String _country = _s.country;

  static const _genders = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];
  static const _countries = [
    '🇺🇿 Uzbekistan', '🇫🇷 France', '🇺🇸 USA', '🇬🇧 UK', '🇪🇸 Spain',
    '🇩🇪 Germany', '🇧🇷 Brazil', '🇯🇵 Japan', '🇰🇷 Korea', '🇮🇳 India',
    '🇷🇺 Russia', '🇹🇷 Turkey', '🇰🇿 Kazakhstan',
  ];

  @override
  void initState() {
    super.initState();
    // Write-through so the wizard always submits the latest values.
    _name.addListener(() => _s.name = _name.text.trim().isEmpty ? _s.name : _name.text.trim());
    _age.addListener(() {
      final a = int.tryParse(_age.text.trim());
      if (a != null && a > 0) _s.age = a;
    });
    _s.gender = _gender;
    _s.country = _country;
    _s.isLearner = _role == 0;
    _s.level = _level;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.x6, Insets.x5, Insets.x6, Insets.x6),
      children: [
        Text('The basics', style: AppText.h2),
        const SizedBox(height: 6),
        Text('This helps us connect you with the right speakers.',
            style: AppText.smMuted),
        const SizedBox(height: 18),
        _TextField(label: 'First name', controller: _name, hint: 'Your name'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: _TextField(
                    label: 'Age',
                    controller: _age,
                    hint: '18',
                    keyboard: TextInputType.number)),
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
                  if (v != null) setState(() { _gender = v; _s.gender = v; });
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
            _seg('🎓 Learner', _role == 0, () => setState(() { _role = 0; _s.isLearner = true; })),
            const SizedBox(width: 10),
            _seg('🎙 Native', _role == 1, () => setState(() { _role = 1; _s.isLearner = false; })),
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
                onTap: () => setState(() { _level = l; _s.level = l; }),
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
            if (v != null) setState(() { _country = v; _s.country = v; });
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
  late final Set<String> _selected = {...AppState.instance.interests};

  void _sync() => AppState.instance.interests = _selected.toList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.x6, Insets.x5, Insets.x6, Insets.x6),
      children: [
        Text('What are you into?', style: AppText.h2),
        const SizedBox(height: 6),
        Text('Pick at least 3 — great conversations start here.',
            style: AppText.smMuted),
        const SizedBox(height: 18),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final i in _all)
              GestureDetector(
                onTap: () => setState(() {
                  _selected.contains(i) ? _selected.remove(i) : _selected.add(i);
                  _sync();
                }),
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
  Set<int> get _on => AppState.instance.onboardingGoals;
  final _goals = const [
    ('🚀', 'Level up my speaking', 'Practice with natives, become fluent'),
    ('🤝', 'Grow my network', 'Meet people & professionals worldwide'),
    ('🌍', 'Explore cultures', 'Learn how the world really talks'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(Insets.x6, Insets.x5, Insets.x6, Insets.x6),
      children: [
        Text('Why are you here?', style: AppText.h2),
        const SizedBox(height: 6),
        Text('Pick what matters to you — it shapes your experience.',
            style: AppText.smMuted),
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

class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;
  const _TextField(
      {required this.label,
      required this.controller,
      this.hint = '',
      this.keyboard});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: TextField(
            controller: controller,
            keyboardType: keyboard,
            style: AppText.body,
            cursorColor: AppColors.brand400,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.body.copyWith(color: AppColors.n300),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                borderSide: const BorderSide(color: AppColors.brand500),
              ),
            ),
          ),
        ),
      ],
    );
  }
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
