import 'package:flutter/material.dart';

import '../../presentation/theme/app_spacing.dart';
import '../../presentation/theme/app_typography.dart';
import '../theme/app_theme.dart';

class TickerTape extends StatelessWidget {
  const TickerTape({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: double.infinity,
      color: AppTheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.centerLeft,
      child: Text(
        'SYSTEM OPERATIONAL  •  FLIGHT OPS ACTIVE  •  AI COMPETITORS LIVE  •  GLOBAL RANKINGS ONLINE  •  CASH RUNWAY STABLE',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.badgeText.copyWith(
          color: Colors.black,
          fontSize: 10,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
