import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class AppTypography {
  // Primary Text Colors mapped dynamically to AppTheme
  static Color get textPrimary => AppTheme.textPrimary;
  static Color get textSecondary => AppTheme.textSecondary;
  static Color get textMuted => AppTheme.textMuted;
  static Color get primaryAccent => AppTheme.primary;

  // App/Screen Titles: Max 20pt - 22pt (Bold)
  static TextStyle get screenTitleLarge => GoogleFonts.ibmPlexSans(
    fontSize: 17,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.15,
  );

  static TextStyle get screenTitleMedium => GoogleFonts.ibmPlexSans(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  // Section Headers: Max 15pt - 16pt (SemiBold)
  static TextStyle get sectionHeaderLarge => GoogleFonts.ibmPlexSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
  );

  static TextStyle get sectionHeaderMedium => GoogleFonts.ibmPlexSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
  );

  // Body Text / Card Content: 13pt - 14pt (Regular)
  static TextStyle get bodyLarge => GoogleFonts.ibmPlexSans(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.3,
  );

  static TextStyle get bodyMedium => GoogleFonts.ibmPlexSans(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.3,
  );

  // Captions / Hints / Badges: 11pt - 12pt (Light/Regular)
  static TextStyle get captionRegular => GoogleFonts.ibmPlexSans(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.25,
  );

  static TextStyle get captionLight => GoogleFonts.ibmPlexSans(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textMuted,
    height: 1.25,
  );

  static TextStyle get badgeText => GoogleFonts.ibmPlexSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: primaryAccent,
    letterSpacing: 0.1,
  );

  static TextStyle get buttonText => GoogleFonts.ibmPlexSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    letterSpacing: 0.1,
  );
}
