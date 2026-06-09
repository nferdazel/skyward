import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? description;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.sectionHeaderLarge,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            description!,
            style: AppTypography.captionRegular,
          ),
        ],
      ],
    );
  }
}
