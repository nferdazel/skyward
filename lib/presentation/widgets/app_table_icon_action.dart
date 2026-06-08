import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppTableIconAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  const AppTableIconAction({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? AppTheme.primary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: foreground.withValues(alpha: 0.08),
            border: Border.all(
              color: foreground.withValues(alpha: 0.24),
              width: 1.0,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: onPressed == null ? AppTheme.textMuted : foreground,
          ),
        ),
      ),
    );
  }
}
