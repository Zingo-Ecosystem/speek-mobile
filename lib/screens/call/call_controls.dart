import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

enum CallControlVariant { normal, end, accept, active }

class CallControl extends StatelessWidget {
  final IconData icon;
  final String? label;
  final CallControlVariant variant;
  final VoidCallback? onTap;
  final bool small;

  const CallControl({
    super.key,
    required this.icon,
    this.label,
    this.variant = CallControlVariant.normal,
    this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 54.0 : 62.0;
    final (bg, fg) = switch (variant) {
      CallControlVariant.end => (AppColors.danger, Colors.white),
      CallControlVariant.accept => (AppColors.success, const Color(0xFF042204)),
      CallControlVariant.active => (
          AppColors.brand500.withValues(alpha: 0.4),
          Colors.white
        ),
      CallControlVariant.normal => (
          Colors.white.withValues(alpha: 0.16),
          Colors.white
        ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: fg, size: small ? 22 : 26),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(label!,
              style: AppText.caption.copyWith(
                  color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ],
    );
  }
}
