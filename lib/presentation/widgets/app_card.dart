import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Border? customBorder;

  const AppCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.margin = EdgeInsets.zero,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: backgroundColor ?? AppTheme.surface,
      border: customBorder ??
          Border.all(
            color: borderColor ?? AppTheme.border,
            width: borderWidth,
          ),
    );

    final card = Container(
      margin: margin,
      padding: padding,
      decoration: customBorder != null
          ? decoration
          : decoration.copyWith(
              borderRadius: BorderRadius.circular(4),
            ),
      child: child,
    );

    if (customBorder != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(4), child: card);
    }
    return card;
  }
}
