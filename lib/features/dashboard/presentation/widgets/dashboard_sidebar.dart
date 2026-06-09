import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';

class DashboardSidebar extends StatelessWidget {
  const DashboardSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    const navItems = [
      AppStrings.dashboardOverview,
      AppStrings.dashboardHangar,
      AppStrings.dashboardRoutes,
      AppStrings.dashboardLedger,
      AppStrings.dashboardLeaderboard,
      AppStrings.dashboardSettings,
    ];
    const navIcons = [
      Icons.terminal,
      Icons.flight,
      Icons.map,
      Icons.receipt_long,
      Icons.emoji_events,
      Icons.settings,
    ];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          right: BorderSide(color: AppTheme.border, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppStrings.skyward,
                style: AppTypography.screenTitleLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: BlocBuilder<NavigationCubit, NavigationState>(
              builder: (context, state) {
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  children: [
                    _buildSectionHeader('OPERATIONS'),
                    _buildNavItem(
                      context,
                      navItems[0],
                      navIcons[0],
                      state.activeIndex == 0,
                      () => context.read<NavigationCubit>().selectTab(0),
                    ),
                    _buildNavItem(
                      context,
                      navItems[1],
                      navIcons[1],
                      state.activeIndex == 1,
                      () => context.read<NavigationCubit>().selectTab(1),
                    ),
                    _buildNavItem(
                      context,
                      navItems[2],
                      navIcons[2],
                      state.activeIndex == 2,
                      () => context.read<NavigationCubit>().selectTab(2),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionHeader('ANALYTICS'),
                    _buildNavItem(
                      context,
                      navItems[3],
                      navIcons[3],
                      state.activeIndex == 3,
                      () => context.read<NavigationCubit>().selectTab(3),
                    ),
                    _buildNavItem(
                      context,
                      navItems[4],
                      navIcons[4],
                      state.activeIndex == 4,
                      () => context.read<NavigationCubit>().selectTab(4),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSectionHeader('SYSTEM'),
                    _buildNavItem(
                      context,
                      navItems[5],
                      navIcons[5],
                      state.activeIndex == 5,
                      () => context.read<NavigationCubit>().selectTab(5),
                    ),
                  ],
                );
              },
            ),
          ),
          Divider(color: AppTheme.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: InkWell(
                onTap: () => context.read<AuthCubit>().logout(),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppTheme.error, size: 18),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        AppStrings.logoutOperations.toUpperCase(),
                        style: AppTypography.microLabel.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTypography.microLabel.copyWith(
          color: AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String label,
    IconData icon,
    bool isActive,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: isActive ? AppTheme.accentSubtle : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          hoverColor: AppTheme.primary.withValues(alpha: 0.06),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: isActive
                  ? Border(
                      left: BorderSide(
                        color: AppTheme.primary,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.bodyLarge.copyWith(
                      color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
