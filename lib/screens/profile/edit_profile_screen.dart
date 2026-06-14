import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/snack.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _s = AppState.instance;
  late final _name = TextEditingController(text: _s.name);
  late final _age = TextEditingController(text: '${_s.age}');
  late final _city = TextEditingController(text: _s.city);
  late final _bio = TextEditingController(text: _s.bio);
  late String _gender = _s.gender;
  late String _country = _s.country;
  late String _level = _s.level;
  late bool _isLearner = _s.isLearner;

  static const _genders = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];
  static const _countries = [
    '🇫🇷 France', '🇺🇸 USA', '🇬🇧 UK', '🇪🇸 Spain', '🇩🇪 Germany',
    '🇧🇷 Brazil', '🇯🇵 Japan', '🇰🇷 Korea', '🇮🇳 India', '🇺🇿 Uzbekistan',
  ];

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _city.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _save() {
    _s.saveProfile(
      name: _name.text.trim().isEmpty ? _s.name : _name.text.trim(),
      age: int.tryParse(_age.text.trim()) ?? _s.age,
      gender: _gender,
      country: _country,
      city: _city.text.trim(),
      level: _level,
      isLearner: _isLearner,
      bio: _bio.text.trim(),
    );
    showSnack(context, 'Profile updated', type: SnackType.success);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return AdaptiveScaffold(
      body: Column(
        children: [
          Padding(
            padding:
                EdgeInsets.fromLTRB(Insets.x4, topPad + 12, Insets.x4, 14),
            child: Row(
              children: [
                SquareIconButton(Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop()),
                Expanded(
                  child: Text('Edit profile',
                      textAlign: TextAlign.center,
                      style: AppText.h3.copyWith(fontSize: 16)),
                ),
                TextButton(
                  onPressed: _save,
                  child: Text('Save',
                      style: AppText.label.copyWith(color: AppColors.brand300)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  Insets.x5, 0, Insets.x5, Insets.x8),
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.brand500, width: 2),
                        ),
                        child: Avatar(Mock.me.photoUrl, size: 96),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                              gradient: AppColors.grad,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _input('First name', _name),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _input('Age', _age,
                            keyboard: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _picker('Gender', _gender, () async {
                        final v = await pickOption(context,
                            title: 'Gender',
                            options: _genders,
                            selected: _gender);
                        if (v != null) setState(() => _gender = v);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _input('City', _city),
                const SizedBox(height: 16),
                _picker('Country', _country, () async {
                  final v = await pickOption(context,
                      title: 'Country',
                      options: _countries,
                      selected: _country);
                  if (v != null) setState(() => _country = v);
                }),
                const SizedBox(height: 16),
                _label('I am a…'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _seg('🎓 Learner', _isLearner,
                        () => setState(() => _isLearner = true)),
                    const SizedBox(width: 10),
                    _seg('🎙 Native', !_isLearner,
                        () => setState(() => _isLearner = false)),
                  ],
                ),
                if (_isLearner) ...[
                  const SizedBox(height: 16),
                  _label('English level'),
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
                ],
                const SizedBox(height: 16),
                _input('About you', _bio, maxLines: 3),
                const SizedBox(height: 24),
                PrimaryButton('Save changes', onTap: _save),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) =>
      Text(t, style: AppText.label.copyWith(color: AppColors.sText2));

  Widget _input(String label, TextEditingController c,
      {TextInputType? keyboard, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        TextField(
          controller: c,
          keyboardType: keyboard,
          maxLines: maxLines,
          style: AppText.body,
          cursorColor: AppColors.brand400,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.sFill(0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              borderSide:
                  BorderSide(color: AppColors.sFill(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              borderSide:
                  BorderSide(color: AppColors.sFill(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Radii.md),
              borderSide: const BorderSide(color: AppColors.brand500),
            ),
          ),
        ),
      ],
    );
  }

  Widget _picker(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.sFill(0.05),
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: AppColors.sFill(0.1)),
            ),
            child: Row(
              children: [
                Expanded(child: Text(value, style: AppText.body)),
                Icon(Icons.keyboard_arrow_down, color: AppColors.sText3),
              ],
            ),
          ),
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
                : AppColors.sFill(0.05),
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(
                color:
                    on ? AppColors.brand500 : AppColors.sFill(0.1)),
          ),
          child: Text(label,
              style: AppText.label.copyWith(
                  color: on ? AppColors.brand200 : AppColors.sText)),
        ),
      ),
    );
  }
}
