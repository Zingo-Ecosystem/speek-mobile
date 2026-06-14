import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

enum SnackType { info, success, error }

/// Shows a clearly-visible floating snackbar above the bottom navigation.
void showSnack(BuildContext context, String message,
    {SnackType type = SnackType.info}) {
  final (color, icon) = switch (type) {
    SnackType.success => (AppColors.success, Icons.check_circle_rounded),
    SnackType.error => (AppColors.danger, Icons.error_rounded),
    SnackType.info => (AppColors.brand400, Icons.info_rounded),
  };

  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1C1C28),
      elevation: 8,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
      content: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: AppText.body
                    .copyWith(color: Colors.white, fontSize: 14)),
          ),
        ],
      ),
    ),
  );
}
