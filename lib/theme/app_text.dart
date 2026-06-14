import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography tokens. Display = Syne, Body = Inter.
///
/// Primary styles leave `color` null so they inherit the ambient
/// [DefaultTextStyle]. The app theme is dark by default (white text); chrome
/// screens that support light mode wrap their body in a DefaultTextStyle using
/// [AppColors.sText], so the same styles render dark text in light mode.
/// Muted styles use the adaptive [AppColors.sText2]/[AppColors.sText3].
class AppText {
  AppText._();

  static TextStyle _syne(double size, FontWeight w, double lh, double ls) =>
      GoogleFonts.syne(
        fontSize: size,
        fontWeight: w,
        height: lh / size,
        letterSpacing: ls,
      );

  static TextStyle _inter(double size, FontWeight w, double lh, {Color? color}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: w,
        height: lh / size,
        color: color,
      );

  // Display / headings (Syne) — inherit color
  static TextStyle get displayLg => _syne(40, FontWeight.w800, 44, -1);
  static TextStyle get displayMd => _syne(32, FontWeight.w800, 36, -0.5);
  static TextStyle get h1 => _syne(29, FontWeight.w800, 33, -0.5);
  static TextStyle get h2 => _syne(22, FontWeight.w700, 28, -0.3);
  static TextStyle get h3 => _syne(18, FontWeight.w700, 24, 0);

  // Body / UI (Inter)
  static TextStyle get bodyLg => _inter(17, FontWeight.w400, 26);
  static TextStyle get body => _inter(15, FontWeight.w400, 22);
  static TextStyle get bodyMuted =>
      _inter(15, FontWeight.w400, 23, color: AppColors.sText2);
  static TextStyle get label => _inter(14, FontWeight.w600, 18);
  static TextStyle get caption =>
      _inter(12, FontWeight.w500, 16, color: AppColors.sText3);
  static TextStyle get smMuted =>
      _inter(12.5, FontWeight.w400, 18, color: AppColors.sText3);
}
