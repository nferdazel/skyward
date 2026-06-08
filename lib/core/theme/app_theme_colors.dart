import 'package:flutter/material.dart';

import 'skyward_colors.dart';

/// Theme extension for Skyward-specific colors.
/// Access via `Theme.of(context).extension<AppThemeColors>()!`
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceSubtle;
  final Color surface3;
  final Color success;
  final Color error;
  final Color warning;
  final Color info;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accentBright;
  final Color accentGhost;

  const AppThemeColors({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceSubtle,
    required this.surface3,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accentBright,
    required this.accentGhost,
  });

  factory AppThemeColors.dark() {
    return const AppThemeColors(
      primary: SkywardColors.darkAccent,
      secondary: SkywardColors.darkAccentDim,
      background: SkywardColors.darkBg,
      surface: SkywardColors.darkSurface,
      surfaceSubtle: SkywardColors.darkBorder,
      surface3: SkywardColors.darkSurface3,
      success: SkywardColors.darkGreen,
      error: SkywardColors.darkRed,
      warning: SkywardColors.darkAmber,
      info: SkywardColors.blue,
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
      secondary: SkywardColors.lightAccentDim,
      background: SkywardColors.lightBg,
      surface: SkywardColors.lightSurface,
      surfaceSubtle: SkywardColors.lightBorder,
      surface3: SkywardColors.lightSurface3,
      success: SkywardColors.lightGreen,
      error: SkywardColors.lightRed,
      warning: SkywardColors.lightAmber,
      info: SkywardColors.blue,
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
    Color? secondary,
    Color? background,
    Color? surface,
    Color? surfaceSubtle,
    Color? surface3,
    Color? success,
    Color? error,
    Color? warning,
    Color? info,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accentBright,
    Color? accentGhost,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surface3: surface3 ?? this.surface3,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
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
      secondary: Color.lerp(secondary, other.secondary, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accentBright: Color.lerp(accentBright, other.accentBright, t)!,
      accentGhost: Color.lerp(accentGhost, other.accentGhost, t)!,
    );
  }
}
