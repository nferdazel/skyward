import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../navigation/presentation/cubit/navigation_cubit.dart';

class DashboardSidebar extends StatelessWidget {
  final double scale;
  const DashboardSidebar({super.key, required this.scale});

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
      width: 68 * scale,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          right: BorderSide(color: AppTheme.surfaceSubtle, width: 1.0),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          RotatedBox(
            quarterTurns: 3,
            child: Text(
              AppStrings.skyward,
              style: AppTypography.screenTitleLarge.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl - AppSpacing.xxs),
          Divider(color: AppTheme.surfaceSubtle, height: 1),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: BlocBuilder<NavigationCubit, NavigationState>(
              builder: (context, state) {
                return ListView.builder(
                  itemCount: navItems.length,
                  itemBuilder: (context, index) {
                    final isActive = state.activeIndex == index;
                    return Container(
                      width: 44 * scale,
                      height: 60 * scale,
                      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          InkWell(
                            onTap: () => context
                                .read<NavigationCubit>()
                                .selectTab(index),
                            child: Tooltip(
                              message: navItems[index],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    navIcons[index],
                                    color: isActive
                                        ? AppTheme.primary
                                        : AppTheme.textSecondary,
                                    size: 20 * scale,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    navItems[index].substring(0, 3),
                                    style: AppTypography.badgeText.copyWith(
                                      letterSpacing: 0.5,
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isActive
                                          ? AppTheme.primary
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isActive)
                            Positioned(
                              right: 0,
                              child: Container(
                                width: 3.0,
                                height: 18.0 * scale,
                                color: AppTheme.primary,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Divider(color: AppTheme.surfaceSubtle, height: 1),
          Container(
            width: 44 * scale,
            height: 52 * scale,
            alignment: Alignment.center,
            child: IconButton(
              icon: Icon(Icons.logout, color: AppTheme.error, size: 20),
              tooltip: AppStrings.logoutOperations,
              onPressed: () => context.read<AuthCubit>().logout(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
