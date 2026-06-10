import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

class AppTypography {
  static Color get textPrimary => AppTheme.textPrimary;
  static Color get textSecondary => AppTheme.textSecondary;
  static Color get textMuted => AppTheme.textMuted;
  static Color get primaryAccent => AppTheme.primary;

  // ── DISPLAY / SCREEN TITLES (IBM Plex Mono) ──
  static TextStyle get screenTitleLarge => GoogleFonts.ibmPlexMono(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
    letterSpacing: 0.08,
  );

  static TextStyle get screenTitleMedium => GoogleFonts.ibmPlexMono(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
    letterSpacing: 0.08,
  );

  // ── SECTION HEADERS (IBM Plex Mono, ALL CAPS) ──
  static TextStyle get sectionHeaderLarge => GoogleFonts.ibmPlexMono(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    height: 1.2,
    letterSpacing: 0.12,
  );

  static TextStyle get sectionHeaderMedium => GoogleFonts.ibmPlexMono(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    height: 1.2,
    letterSpacing: 0.12,
  );

  // ── BODY TEXT (Inter) ──
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.4,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );

  // ── MICRO LABELS (IBM Plex Mono, ALL CAPS) ──
  static TextStyle get microLabel => GoogleFonts.ibmPlexMono(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: textSecondary,
    height: 1.2,
    letterSpacing: 0.12,
  );

  // ── CAPTIONS / HINTS (Inter) ──
  static TextStyle get captionRegular => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.25,
  );

  static TextStyle get captionLight => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textMuted,
    height: 1.25,
  );

  // ── BADGE TEXT (IBM Plex Mono, ALL CAPS) ──
  static TextStyle get badgeText => GoogleFonts.ibmPlexMono(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: primaryAccent,
    letterSpacing: 0.08,
  );

  // ── BUTTON TEXT (IBM Plex Mono) ──
  static TextStyle get buttonText => GoogleFonts.ibmPlexMono(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.black,
    letterSpacing: 0.08,
  );

  // ── DATA / MONO STYLES (IBM Plex Mono) ──
  static TextStyle get hudValue => GoogleFonts.ibmPlexMono(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static TextStyle get dataEmphasis => GoogleFonts.ibmPlexMono(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle get largeKpi => GoogleFonts.ibmPlexMono(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.02,
  );

  static TextStyle get telemetry => GoogleFonts.ibmPlexMono(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  // ── MONO VALUE (IBM Plex Mono, for metric values) ──
  static TextStyle get monoValue => GoogleFonts.ibmPlexMono(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  // ── MONO LABEL (IBM Plex Mono, for compact labels) ──
  static TextStyle get monoLabel => GoogleFonts.ibmPlexMono(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.08,
  );
}
