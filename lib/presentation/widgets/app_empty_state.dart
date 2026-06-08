import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_card.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final EdgeInsetsGeometry padding;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.padding = const EdgeInsets.symmetric(vertical: 40),
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: padding,
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppTypography.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTypography.badgeText.copyWith(
                color: AppTypography.textPrimary,
                letterSpacing: 0.8,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
