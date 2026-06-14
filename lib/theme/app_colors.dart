import 'package:flutter/material.dart';

/// Speek design tokens — colors. Mirrors `ui-ux design/tokens.json`.
class AppColors {
  AppColors._();

  // Brand
  static const brand50 = Color(0xFFF0EEFF);
  static const brand100 = Color(0xFFE1DEFF);
  static const brand200 = Color(0xFFC7C2FF);
  static const brand300 = Color(0xFFA8A0FF);
  static const brand400 = Color(0xFF8B84FF);
  static const brand500 = Color(0xFF6C63FF); // primary
  static const brand600 = Color(0xFF4F47D6);
  static const brand700 = Color(0xFF3B34A8);
  static const brand800 = Color(0xFF2D2B8F);
  static const brand900 = Color(0xFF1E1C5E);

  // Neutral
  static const n0 = Color(0xFFFFFFFF);
  static const n50 = Color(0xFFECECF2);
  static const n100 = Color(0xFFC9C9D6);
  static const n200 = Color(0xFF9A9AB0);
  static const n300 = Color(0xFF6E6E85);
  static const n400 = Color(0xFF43435A);
  static const n500 = Color(0xFF2A2A3A);
  static const n600 = Color(0xFF1C1C2A);
  static const n700 = Color(0xFF15151F);
  static const n800 = Color(0xFF0F0F17);
  static const n900 = Color(0xFF0A0A0F); // app background

  // Status / accent
  static const success = Color(0xFF45E07A);
  static const success500 = Color(0xFF22B85A);
  static const warning = Color(0xFFFFB547);
  static const danger = Color(0xFFFF3B3B);
  static const like = Color(0xFFFF6FB5);
  static const cyan = Color(0xFF3DD6E0);
  static const gold = Color(0xFFFFD66B);

  // Semantic
  static const bgApp = n900;
  static const bgSurface = n700;
  static const bgSurface2 = n600;
  static const bgElevated = n500;
  static const textPrimary = n50;
  static const textSecondary = n200;
  static const textMuted = n300;

  static const borderSubtle = Color(0x14FFFFFF); // rgba(255,255,255,.08)
  static const borderStrong = Color(0x2EFFFFFF); // rgba(255,255,255,.18)
  static Color get borderBrand => brand500.withValues(alpha: 0.40);

  /// Whether the app is currently in light mode. Set by the root from
  /// AppState. The `s*` adaptive getters below flip on this so the app
  /// "chrome" (tabs, lists, settings, profile) can switch theme. Immersive
  /// screens (onboarding, calls, map, paywall) keep the raw dark palette.
  static bool isLight = false;

  static Color get sBg => isLight ? const Color(0xFFF4F4F8) : n900;
  static Color get sSurface => isLight ? Colors.white : n700;
  static Color get sCard =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF15151F);
  static Color get sText => isLight ? const Color(0xFF15151F) : n50;
  static Color get sText2 => isLight ? const Color(0xFF43435A) : n200;
  static Color get sText3 => isLight ? const Color(0xFF8A8A9A) : n300;
  static Color get sDivider =>
      isLight ? const Color(0x14000000) : const Color(0x14FFFFFF);
  static Color sFill(double a) =>
      (isLight ? Colors.black : Colors.white).withValues(alpha: a);

  // Gradients
  static const grad = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand500, brand600],
  );
  static const gradDeep = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand800, brand500],
  );
  static const gradGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD66B), Color(0xFFF0A93B)],
  );
}
