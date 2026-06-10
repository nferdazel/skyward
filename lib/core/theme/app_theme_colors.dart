import 'package:flutter/material.dart';

import 'skyward_colors.dart';

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color primary;
  final Color accentSubtle;
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color borderSubtle;
  final Color success;
  final Color successSubtle;
  final Color error;
  final Color errorSubtle;
  final Color warning;
  final Color warningSubtle;
  final Color info;
  final Color neutral;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accentBright;
  final Color accentGhost;

  const AppThemeColors({
    required this.primary,
    required this.accentSubtle,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.borderSubtle,
    required this.success,
    required this.successSubtle,
    required this.error,
    required this.errorSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.info,
    required this.neutral,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accentBright,
    required this.accentGhost,
  });

  factory AppThemeColors.dark() {
    return const AppThemeColors(
      primary: SkywardColors.darkAccent,
      accentSubtle: SkywardColors.darkAccentSubtle,
      background: SkywardColors.darkBg,
      surface: SkywardColors.darkSurface,
      surfaceRaised: SkywardColors.darkSurface2,
      border: SkywardColors.darkBorder,
      borderSubtle: SkywardColors.darkBorder2,
      success: SkywardColors.darkGreen,
      successSubtle: SkywardColors.darkGreenSubtle,
      error: SkywardColors.darkRed,
      errorSubtle: SkywardColors.darkRedSubtle,
      warning: SkywardColors.darkAmber,
      warningSubtle: SkywardColors.darkAmberSubtle,
      info: SkywardColors.darkAccent,
      neutral: SkywardColors.darkNeutral,
      textPrimary: SkywardColors.darkTextPri,
      textSecondary: SkywardColors.darkTextSec,
      textMuted: SkywardColors.darkTextDim,
      accentBright: SkywardColors.darkAccentBright,
      accentGhost: SkywardColors.darkAccentGhost,
    );
  }

  factory AppThemeColors.light() {
    return const AppThemeColors(
      primary: SkywardColors.lightAccent,
      accentSubtle: SkywardColors.lightAccentSubtle,
      background: SkywardColors.lightBg,
      surface: SkywardColors.lightSurface,
      surfaceRaised: SkywardColors.lightSurface2,
      border: SkywardColors.lightBorder,
      borderSubtle: SkywardColors.lightBorder2,
      success: SkywardColors.lightGreen,
      successSubtle: SkywardColors.lightGreenSubtle,
      error: SkywardColors.lightRed,
      errorSubtle: SkywardColors.lightRedSubtle,
      warning: SkywardColors.lightAmber,
      warningSubtle: SkywardColors.lightAmberSubtle,
      info: SkywardColors.lightAccent,
      neutral: SkywardColors.lightNeutral,
      textPrimary: SkywardColors.lightTextPri,
      textSecondary: SkywardColors.lightTextSec,
      textMuted: SkywardColors.lightTextDim,
      accentBright: SkywardColors.lightAccentBright,
      accentGhost: SkywardColors.lightAccentGhost,
    );
  }

  static AppThemeColors of(BuildContext context) {
    final extension = Theme.of(context).extension<AppThemeColors>();
    return extension ?? AppThemeColors.dark();
  }

  @override
  ThemeExtension<AppThemeColors> copyWith({
    Color? primary,
    Color? accentSubtle,
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? borderSubtle,
    Color? success,
    Color? successSubtle,
    Color? error,
    Color? errorSubtle,
    Color? warning,
    Color? warningSubtle,
    Color? info,
    Color? neutral,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accentBright,
    Color? accentGhost,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      accentSubtle: accentSubtle ?? this.accentSubtle,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      success: success ?? this.success,
      successSubtle: successSubtle ?? this.successSubtle,
      error: error ?? this.error,
      errorSubtle: errorSubtle ?? this.errorSubtle,
      warning: warning ?? this.warning,
      warningSubtle: warningSubtle ?? this.warningSubtle,
      info: info ?? this.info,
      neutral: neutral ?? this.neutral,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accentBright: accentBright ?? this.accentBright,
      accentGhost: accentGhost ?? this.accentGhost,
    );
  }

  @override
  ThemeExtension<AppThemeColors> lerp(
    ThemeExtension<AppThemeColors>? other,
    double t,
  ) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      accentSubtle: Color.lerp(accentSubtle, other.accentSubtle, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSubtle: Color.lerp(successSubtle, other.successSubtle, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSubtle: Color.lerp(errorSubtle, other.errorSubtle, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSubtle: Color.lerp(warningSubtle, other.warningSubtle, t)!,
      info: Color.lerp(info, other.info, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accentBright: Color.lerp(accentBright, other.accentBright, t)!,
      accentGhost: Color.lerp(accentGhost, other.accentGhost, t)!,
    );
  }
}
