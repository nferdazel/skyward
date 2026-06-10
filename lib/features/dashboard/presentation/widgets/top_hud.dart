import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/pulse_dot.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../simulation/presentation/cubit/simulation_state.dart';

class TopHud extends StatelessWidget {
  final AuthAuthenticated authState;
  final SimulationState simState;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;

  const TopHud({
    super.key,
    required this.authState,
    required this.simState,
    required this.currencyFormat,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    final user = authState.user;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Company name
          _buildPill(
            label: user.companyName.toUpperCase(),
            value: user.ceoName,
            color: AppTheme.textPrimary,
          ),
          _buildDivider(),
          // Game clock
          _buildPill(
            label: AppStrings.gameClockUtc.toUpperCase(),
            value: dateFormat.format(simState.gameTime),
            color: AppTheme.primary,
            isMono: true,
          ),
          _buildDivider(),
          // Cash balance
          _buildPill(
            label: AppStrings.cashBalanceLabel.toUpperCase(),
            value: currencyFormat.format(simState.cashBalance),
            color: AppTheme.success,
            isMono: true,
          ),
          _buildDivider(),
          // Fuel price
          _buildPill(
            label: AppStrings.fuelPriceLabel.toUpperCase(),
            value: '\$${simState.fuelPricePerLiter.toStringAsFixed(2)}/L',
            color: AppTheme.warning,
            isMono: true,
          ),
          _buildDivider(),
          // Live status
          _buildLiveStatus(simState),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: AppTheme.border,
    );
  }

  Widget _buildPill({
    required String label,
    required String value,
    required Color color,
    bool isMono = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.microLabel.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (isMono ? AppTypography.monoValue : AppTypography.bodyLarge)
                  .copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatus(SimulationState simState) {
    final isLive = !simState.isSyncing;
    final statusColor = isLive ? AppTheme.success : AppTheme.warning;
    final statusText = isLive
        ? AppStrings.liveLabel.toUpperCase()
        : AppStrings.syncingLabel.toUpperCase();

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulseDot(color: statusColor, size: 6),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                statusText,
                style: AppTypography.badgeText.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
