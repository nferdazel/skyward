import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../presentation/widgets/app_badge.dart';

class AIBadge extends StatelessWidget {
  const AIBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBadge.secondary(label: AppStrings.aiLabel);
  }
}

class LeaderboardTableHeaderCell extends StatelessWidget {
  final String text;
  const LeaderboardTableHeaderCell({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Text(
        text,
        style: AppTypography.badgeText.copyWith(
          color: AppTypography.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class LeaderboardTableCell extends StatelessWidget {
  final String text;
  final Color? color;
  final bool isBold;
  final bool isMono;

  const LeaderboardTableCell({
    super.key,
    required this.text,
    this.color,
    this.isBold = false,
    this.isMono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Text(
        text,
        style: AppTypography.badgeText.copyWith(
          fontSize: 11,
          color: color ?? AppTypography.textPrimary,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          letterSpacing: isMono ? 0.0 : 0.5,
        ),
      ),
    );
  }
}

class RankCell extends StatelessWidget {
  final int rank;
  final bool isHuman;
  const RankCell({super.key, required this.rank, required this.isHuman});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isHuman
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surfaceSubtle.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Text(
          '$rank',
          style: AppTypography.badgeText.copyWith(
            color: isHuman ? AppTheme.primary : AppTypography.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
