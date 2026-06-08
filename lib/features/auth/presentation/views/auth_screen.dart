// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../../../presentation/theme/app_spacing.dart';
import '../../../../presentation/theme/app_typography.dart';
import '../../../../presentation/widgets/app_button.dart';
import '../../../../presentation/widgets/app_snackbar.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class AuthModeCubit extends Cubit<bool> {
  AuthModeCubit() : super(true);
  void toggle() => emit(!state);
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final GlobalKey<FormState> _formKey;

  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _companyController;
  late final TextEditingController _ceoController;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _companyController = TextEditingController();
    _ceoController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    _ceoController.dispose();
    super.dispose();
  }

  void _submitForm(BuildContext context, bool isLoginMode) {
    if (_formKey.currentState?.validate() ?? false) {
      final cubit = context.read<AuthCubit>();
      if (isLoginMode) {
        cubit.login(
          username: _usernameController.text,
          password: _passwordController.text,
        );
      } else {
        cubit.register(
          username: _usernameController.text,
          password: _passwordController.text,
          companyName: _companyController.text,
          ceoName: _ceoController.text,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthModeCubit>(
      create: (context) => AuthModeCubit(),
      child: Scaffold(
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
          if (state is AuthError) {
              AppSnackBar.showError(context, state.message);
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Container(
              color: AppTheme.background,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  child: ResponsiveLayout(
                    mobileBody: BlocBuilder<AuthModeCubit, bool>(
                      builder: (context, isLoginMode) => _buildFormCard(
                        context,
                        isLoading,
                        isLoginMode,
                        isMobile: true,
                      ),
                    ),
                    desktopBody: BlocBuilder<AuthModeCubit, bool>(
                      builder: (context, isLoginMode) => ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: _buildFormCard(
                          context,
                          isLoading,
                          isLoginMode,
                          isMobile: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFormCard(
    BuildContext context,
    bool isLoading,
    bool isLoginMode, {
    required bool isMobile,
  }) {
    final formContent = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isMobile) ...[
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
                child: const Icon(
                  Icons.flight_takeoff,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                AppStrings.skyward,
                style: AppTypography.screenTitleMedium.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            isLoginMode ? AppStrings.welcomeCeo : AppStrings.establishAirline,
            style: AppTypography.screenTitleMedium.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isLoginMode
                ? AppStrings.signInCommand
                : AppStrings.registerCorporate,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Username
          TextFormField(
            controller: _usernameController,
            keyboardType: TextInputType.name,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: AppStrings.usernameLabel,
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return AppStrings.enterValidUsername;
              if (value.trim().length < 4)
                return AppStrings.usernameMinLength;
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            enabled: !isLoading,
            decoration: const InputDecoration(
              labelText: AppStrings.passwordLabel,
              prefixIcon: Icon(Icons.lock_outline, size: 20),
            ),
            validator: (value) {
              if (value == null || value.isEmpty)
                return AppStrings.enterValidPassword;
              if (value.length < 6)
                return AppStrings.passwordMinLength;
              return null;
            },
          ),
          if (!isLoginMode) ...[
            const SizedBox(height: AppSpacing.lg),
            // Company Name
            TextFormField(
              controller: _companyController,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: AppStrings.companyNameAuthLabel,
                prefixIcon: Icon(Icons.business_outlined, size: 20),
                hintText: AppStrings.companyNameAuthHint,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return AppStrings.enterCompanyName;
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            // CEO Name
            TextFormField(
              controller: _ceoController,
              enabled: !isLoading,
              decoration: const InputDecoration(
                labelText: AppStrings.ceoDisplayNameLabel,
                prefixIcon: Icon(Icons.badge_outlined, size: 20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty)
                  return AppStrings.enterCeoName;
                return null;
              },
            ),
          ],
          const SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
          // Submit Button
          AppButton(
            text: isLoginMode
                ? AppStrings.executeOperations
                : AppStrings.incorporateCompany,
            onPressed: isLoading
                ? null
                : () => _submitForm(context, isLoginMode),
            isLoading: isLoading,
            width: double.infinity,
            height: 56,
          ),
          const SizedBox(height: AppSpacing.lg),
          // Mode Toggle Button
          Center(
            child: TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<AuthCubit>().clearError();
                      context.read<AuthModeCubit>().toggle();
                      _formKey.currentState?.reset();
                    },
              child: RichText(
                text: TextSpan(
                  text: isLoginMode
                      ? AppStrings.needCorporatePermit
                      : AppStrings.alreadyRegistered,
                  style: AppTypography.bodyMedium,
                  children: [
                    TextSpan(
                      text: isLoginMode
                          ? AppStrings.registerNow
                          : AppStrings.loginNow,
                      style: AppTypography.badgeText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.surfaceSubtle, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.pagePadding,
          vertical: AppSpacing.xxl + AppSpacing.xs,
        ),
        child: formContent,
      );
    }

    return formContent;
  }
}
