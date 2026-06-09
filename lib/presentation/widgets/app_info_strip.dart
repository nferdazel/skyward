import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../theme/app_spacing.dart';

class AppInfoStrip extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;

  const AppInfoStrip({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: borderColor ?? AppTheme.border,
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}
