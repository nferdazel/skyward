import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppButtonType { primary, secondary }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonType type;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.type = AppButtonType.primary,
    this.icon,
    this.width,
    this.height = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;
    final isPrimary = type == AppButtonType.primary;

    Color getBgColor() {
      if (!isEnabled) return AppTheme.surfaceSubtle;
      return isPrimary ? AppTheme.primary : Colors.transparent;
    }

    Color getTextColor() {
      if (!isEnabled) return AppTheme.textMuted;
      return isPrimary ? Colors.black : AppTheme.primary;
    }

    Border? getBorder() {
      if (isPrimary) return null;
      final borderColor = isEnabled ? AppTheme.primary : AppTheme.surfaceSubtle;
      return Border.all(color: borderColor, width: 1.5);
    }

    return SizedBox(
      width: width,
      height: height,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(color: getBgColor(), border: getBorder()),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(getTextColor()),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: getTextColor()),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        text.toUpperCase(),
                        style: AppTypography.buttonText.copyWith(
                          color: getTextColor(),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
