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
  final double scale;

  const TopHud({
    super.key,
    required this.authState,
    required this.simState,
    required this.currencyFormat,
    required this.dateFormat,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final user = authState.user;

    return Container(
      height: 48 * scale,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceSubtle, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          _buildCompanyInfo(context, user),
          Container(width: 1.0, color: AppTheme.surfaceSubtle),
          _buildGameClock(context, simState, dateFormat),
          Container(width: 1.0, color: AppTheme.surfaceSubtle),
          _buildCashBalance(context, simState, currencyFormat),
          Container(width: 1.0, color: AppTheme.surfaceSubtle),
          _buildFuelPrice(context, simState),
          Container(width: 1.0, color: AppTheme.surfaceSubtle),
          _buildLiveStatus(context, simState),
        ],
      ),
    );
  }

  Widget _buildCompanyInfo(BuildContext context, dynamic user) {
    return Expanded(
      flex: 3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.companyName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.sectionHeaderLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              user.ceoName,
              style: AppTypography.captionRegular.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameClock(
    BuildContext context,
    SimulationState simState,
    DateFormat dateFormat,
  ) {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.gameClockUtc,
              style: AppTypography.captionLight.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              dateFormat.format(simState.gameTime),
              style: AppTypography.badgeText.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.primary,
                letterSpacing: 0.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashBalance(
    BuildContext context,
    SimulationState simState,
    NumberFormat currencyFormat,
  ) {
    return Expanded(
      flex: 3,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.cashBalanceLabel,
              style: AppTypography.captionLight.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              currencyFormat.format(simState.cashBalance),
              style: AppTypography.sectionHeaderMedium.copyWith(
                fontFamily: AppTypography.badgeText.fontFamily,
                fontWeight: FontWeight.w600,
                color: AppTheme.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelPrice(BuildContext context, SimulationState simState) {
    return Expanded(
      flex: 2,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.fuelPriceLabel,
              style: AppTypography.captionLight.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              '\$${simState.fuelPricePerLiter.toStringAsFixed(2)}/L',
              style: AppTypography.badgeText.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.warning,
                letterSpacing: 0.0,
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulseDot(
              color: simState.isSyncing ? AppTheme.warning : AppTheme.success,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              simState.isSyncing
                  ? AppStrings.syncingLabel
                  : AppStrings.liveLabel,
              style: AppTypography.badgeText.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
                color: simState.isSyncing ? AppTheme.warning : AppTheme.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
