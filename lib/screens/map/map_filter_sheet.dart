import 'package:flutter/material.dart';

import '../../data/api_enums.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Active map filter state.
class MapFilter {
  final int? role; // null = all, 0 = learner, 1 = native
  final int? maxCefrLevel; // null = any; index into CEFR list
  final String countryCode;
  final int goals; // bitmask

  const MapFilter({
    this.role,
    this.maxCefrLevel,
    this.countryCode = '',
    this.goals = 0,
  });

  bool get isEmpty =>
      role == null && maxCefrLevel == null && countryCode.isEmpty && goals == 0;

  MapFilter copyWith({
    Object? role = _sentinel,
    Object? maxCefrLevel = _sentinel,
    String? countryCode,
    int? goals,
  }) =>
      MapFilter(
        role: role == _sentinel ? this.role : role as int?,
        maxCefrLevel: maxCefrLevel == _sentinel
            ? this.maxCefrLevel
            : maxCefrLevel as int?,
        countryCode: countryCode ?? this.countryCode,
        goals: goals ?? this.goals,
      );
}

const _sentinel = Object();

// Goals bitmask values (must match backend LearningGoals enum).
const _goalDefs = [
  (bit: 1, label: 'Business'),
  (bit: 2, label: 'Travel'),
  (bit: 4, label: 'Academic'),
  (bit: 8, label: 'Casual'),
  (bit: 16, label: 'Cultural'),
];

Future<MapFilter?> showMapFilter(BuildContext context, MapFilter current) {
  return showModalBottomSheet<MapFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MapFilterSheet(current: current),
  );
}

class _MapFilterSheet extends StatefulWidget {
  final MapFilter current;
  const _MapFilterSheet({required this.current});

  @override
  State<_MapFilterSheet> createState() => _MapFilterSheetState();
}

class _MapFilterSheetState extends State<_MapFilterSheet> {
  late int? _role;
  late int? _maxCefrLevel;
  late String _countryCode;
  late int _goals;

  static const _cefrLabels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'Native'];

  @override
  void initState() {
    super.initState();
    _role = widget.current.role;
    _maxCefrLevel = widget.current.maxCefrLevel;
    _countryCode = widget.current.countryCode;
    _goals = widget.current.goals;
  }

  void _toggleGoal(int bit) {
    setState(() => _goals = _goals ^ bit);
  }

  void _apply() {
    Navigator.of(context).pop(MapFilter(
      role: _role,
      maxCefrLevel: _maxCefrLevel,
      countryCode: _countryCode,
      goals: _goals,
    ));
  }

  void _reset() {
    setState(() {
      _role = null;
      _maxCefrLevel = null;
      _countryCode = '';
      _goals = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + Insets.x6),
      decoration: const BoxDecoration(
        color: AppColors.n800,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Color(0x4D6C63FF))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Insets.x5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter', style: AppText.h2),
                  GestureDetector(
                    onTap: _reset,
                    child: Text('Reset',
                        style: AppText.label
                            .copyWith(color: AppColors.brand300)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Role
              Text('Role', style: AppText.label),
              const SizedBox(height: 8),
              Row(
                children: [
                  _chip('All', _role == null, () => setState(() => _role = null)),
                  const SizedBox(width: 8),
                  _chip(
                      'Learner', _role == 0, () => setState(() => _role = 0)),
                  const SizedBox(width: 8),
                  _chip(
                      'Native', _role == 1, () => setState(() => _role = 1)),
                ],
              ),
              const SizedBox(height: 20),

              // Max CEFR level (only meaningful for learners)
              Text('Max CEFR level', style: AppText.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip('Any', _maxCefrLevel == null,
                      () => setState(() => _maxCefrLevel = null)),
                  for (int i = 0; i < _cefrLabels.length; i++)
                    _chip(
                      _cefrLabels[i],
                      _maxCefrLevel == i + 1,
                      () => setState(() =>
                          _maxCefrLevel = ApiEnums.cefrToInt(_cefrLabels[i])),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Country code
              Text('Country code', style: AppText.label),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: _countryCode),
                onChanged: (v) => _countryCode = v.trim().toUpperCase(),
                style: AppText.body,
                textCapitalization: TextCapitalization.characters,
                maxLength: 2,
                decoration: InputDecoration(
                  hintText: 'e.g. US, GB, UZ',
                  hintStyle: AppText.body.copyWith(color: AppColors.sText3),
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.sFill(0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Goals
              Text('Learning goals', style: AppText.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final g in _goalDefs)
                    _chip(
                      g.label,
                      _goals & g.bit != 0,
                      () => _toggleGoal(g.bit),
                    ),
                ],
              ),
              const SizedBox(height: 28),

              PrimaryButton('Apply filters', onTap: _apply),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brand500.withValues(alpha: 0.2)
              : AppColors.sFill(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.brand500.withValues(alpha: 0.6)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppText.label.copyWith(
            color: selected ? AppColors.brand200 : AppColors.sText2,
          ),
        ),
      ),
    );
  }
}
