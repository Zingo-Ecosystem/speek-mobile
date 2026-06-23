import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

/// Collapsible "Have an invite code?" row that reveals a code input.
///
/// The friend who was invited types the promo code here so that, at sign-up,
/// both they and the inviter get the referral reward (+10 days Premium).
/// Used on the sign-up screen and the map register gate.
class InviteCodeField extends StatefulWidget {
  final TextEditingController controller;

  /// Optional starting value, e.g. parsed from a deep link in the future.
  final bool startExpanded;

  const InviteCodeField({
    super.key,
    required this.controller,
    this.startExpanded = false,
  });

  /// Reads a clean, upper-cased code (or null if empty) from a controller.
  static String? readCode(TextEditingController c) {
    final v = c.text.trim().toUpperCase();
    return v.isEmpty ? null : v;
  }

  @override
  State<InviteCodeField> createState() => _InviteCodeFieldState();
}

class _InviteCodeFieldState extends State<InviteCodeField> {
  late bool _expanded = widget.startExpanded;

  @override
  Widget build(BuildContext context) {
    if (!_expanded) {
      return GestureDetector(
        onTap: () => setState(() => _expanded = true),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Text('Have an invite code?',
                  style: AppText.label.copyWith(color: AppColors.brand300)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: AppColors.brand300),
            ],
          ),
        ),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
        decoration: BoxDecoration(
          color: AppColors.brand500.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Radii.md),
          border:
              Border.all(color: AppColors.brand400.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                maxLength: 16,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
                  _UpperCaseFormatter(),
                ],
                style: AppText.body.copyWith(letterSpacing: 2, fontSize: 16),
                cursorColor: AppColors.brand400,
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  border: InputBorder.none,
                  hintText: 'Enter invite code',
                  hintStyle: AppText.body.copyWith(color: AppColors.n300),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                widget.controller.clear();
                setState(() => _expanded = false);
              },
              icon:
                  Icon(Icons.close_rounded, size: 18, color: AppColors.n300),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
