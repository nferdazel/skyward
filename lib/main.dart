import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/database/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/terminal_loader.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/auth_state.dart';
import 'features/auth/presentation/views/auth_screen.dart';
import 'features/dashboard/presentation/views/dashboard_screen.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Connection
  await SupabaseManager.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (context) => AuthCubit()..autoLogin()),
        BlocProvider<SettingsCubit>(create: (context) => SettingsCubit()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            title: 'SKYWARD',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(settingsState.uiScale),
                ),
                child: child!,
              );
            },
            home: const AppRouter(),
          );
        },
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: TerminalLoader(message: 'RESTORING CEO OPERATIONS...'),
            ),
          );
        } else if (state is AuthAuthenticated) {
          return const DashboardScreen();
        } else {
          return AuthScreen();
        }
      },
    );
  }
}
