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
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          _buildSection(
            flex: 3,
            label: null,
            value: user.companyName,
            valueStyle: AppTypography.hudValue.copyWith(
              color: AppTheme.textPrimary,
            ),
            sublabel: user.ceoName,
          ),
          _buildSeparator(),
          _buildSection(
            flex: 2,
            label: AppStrings.gameClockUtc.toUpperCase(),
            value: dateFormat.format(simState.gameTime),
            valueStyle: AppTypography.hudValue.copyWith(
              color: AppTheme.primary,
            ),
          ),
          _buildSeparator(),
          _buildSection(
            flex: 3,
            label: AppStrings.cashBalanceLabel.toUpperCase(),
            value: currencyFormat.format(simState.cashBalance),
            valueStyle: AppTypography.hudValue.copyWith(
              color: AppTheme.success,
            ),
          ),
          _buildSeparator(),
          _buildSection(
            flex: 2,
            label: AppStrings.fuelPriceLabel.toUpperCase(),
            value: '\$${simState.fuelPricePerLiter.toStringAsFixed(2)}/L',
            valueStyle: AppTypography.hudValue.copyWith(
              color: AppTheme.warning,
            ),
          ),
          _buildSeparator(),
          _buildLiveStatus(context, simState),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      width: 1,
      color: AppTheme.border,
    );
  }

  Widget _buildSection({
    required int flex,
    String? label,
    required String value,
    required TextStyle valueStyle,
    String? sublabel,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (label != null) ...[
              Text(
                label,
                style: AppTypography.microLabel.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
            if (sublabel != null)
              Text(
                sublabel,
                style: AppTypography.captionRegular.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatus(BuildContext context, SimulationState simState) {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulseDot(
              color: simState.isSyncing ? AppTheme.warning : AppTheme.success,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              simState.isSyncing
                  ? AppStrings.syncingLabel.toUpperCase()
                  : AppStrings.liveLabel.toUpperCase(),
              style: AppTypography.microLabel.copyWith(
                fontWeight: FontWeight.w600,
                color: simState.isSyncing ? AppTheme.warning : AppTheme.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
