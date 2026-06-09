import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class AppTypography {
  // Primary Text Colors mapped dynamically to AppTheme
  static Color get textPrimary => AppTheme.textPrimary;
  static Color get textSecondary => AppTheme.textSecondary;
  static Color get textMuted => AppTheme.textMuted;
  static Color get primaryAccent => AppTheme.primary;

  // App/Screen Titles: 15px Bold
  static TextStyle get screenTitleLarge => GoogleFonts.ibmPlexSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
  );

  static TextStyle get screenTitleMedium => GoogleFonts.ibmPlexSans(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
  );

  // Section Headers: 13px SemiBold UPPERCASE + letter-spacing
  static TextStyle get sectionHeaderLarge => GoogleFonts.ibmPlexSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
    letterSpacing: 0.08,
  );

  static TextStyle get sectionHeaderMedium => GoogleFonts.ibmPlexSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
    letterSpacing: 0.08,
  );

  // Body Text / Card Content: 13px Regular
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

  // Micro Labels: 11px Medium UPPERCASE + letter-spacing
  static TextStyle get microLabel => GoogleFonts.ibmPlexSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.2,
    letterSpacing: 0.06,
  );

  // Captions / Hints / Badges: 11px - 12px
  static TextStyle get captionRegular => GoogleFonts.ibmPlexSans(
    fontSize: 12,
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
    letterSpacing: 0.02,
  );

  // Button Text: 13px SemiBold
  static TextStyle get buttonText => GoogleFonts.ibmPlexSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    letterSpacing: 0.02,
  );

  // HUD Value: 13px Bold
  static TextStyle get hudValue => GoogleFonts.ibmPlexSans(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  // Data Emphasis: 16px Bold
  static TextStyle get dataEmphasis => GoogleFonts.ibmPlexSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.01,
  );

  // Large KPI: 22px Bold
  static TextStyle get largeKpi => GoogleFonts.ibmPlexSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.02,
  );
}
