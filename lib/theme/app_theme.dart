import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Spacing scale (4pt grid) and radius tokens.
class Insets {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
  static const x8 = 32.0;
  static const x10 = 40.0;
  static const x12 = 48.0;
}

class Radii {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 22.0;
  static const xl2 = 28.0;
  static const pill = 100.0;
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgApp,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brand500,
        secondary: AppColors.brand400,
        surface: AppColors.bgApp,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      splashFactory: InkRipple.splashFactory,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF4F4F8),
      colorScheme: const ColorScheme.light(
        primary: AppColors.brand500,
        secondary: AppColors.brand600,
        surface: Color(0xFFF4F4F8),
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: const Color(0xFF15151F),
        displayColor: const Color(0xFF15151F),
      ),
      splashFactory: InkRipple.splashFactory,
      iconTheme: const IconThemeData(color: Color(0xFF15151F)),
    );
  }

  static const systemOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.n900,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}
