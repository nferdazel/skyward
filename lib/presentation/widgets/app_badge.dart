import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../theme/app_typography.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final double fontSize;
  final double letterSpacing;
  final EdgeInsetsGeometry padding;

  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.fontSize = 9.0,
    this.letterSpacing = 0.8,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  });

  factory AppBadge.success({required String label}) {
    return AppBadge(label: label, color: AppTheme.success);
  }

  factory AppBadge.error({required String label}) {
    return AppBadge(label: label, color: AppTheme.error);
  }

  factory AppBadge.warning({required String label}) {
    return AppBadge(label: label, color: AppTheme.warning);
  }

  factory AppBadge.primary({required String label}) {
    return AppBadge(label: label, color: AppTheme.primary);
  }

  factory AppBadge.secondary({required String label}) {
    return AppBadge(label: label, color: AppTheme.textSecondary);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.0),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.badgeText.copyWith(
          fontSize: fontSize,
          color: color,
          letterSpacing: letterSpacing,
        ),
      ),
    );
  }
}
