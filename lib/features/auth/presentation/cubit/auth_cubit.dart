// ignore_for_file: avoid_print
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/database/supabase_client.dart';
import '../../../../core/utils/dev_mode_manager.dart';
import '../../domain/user_model.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  static const String _tokenKey = 'skyward_session_token';

  AuthCubit() : super(const AuthInitial());

  // Attempt auto-login using persisted local session token
  Future<void> autoLogin() async {
    emit(const AuthLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      if (token == null || token.isEmpty) {
        emit(const AuthUnauthenticated());
        return;
      }

      // Check if credentials are placeholders
      if (DevModeManager.isDevMode) {
        _devFallbackLogin(token);
        return;
      }

      // Execute custom session validation on Supabase server
      final List<dynamic> response = await SupabaseManager.client.rpc(
        'validate_session',
        params: {'p_token': token},
      );

      if (response.isNotEmpty) {
        final result = response[0] as Map<String, dynamic>;
        final success = result['success'] as bool? ?? false;

        if (success) {
          final user = User.fromMap(result);
          emit(AuthAuthenticated(user: user, token: token));
        } else {
          // Token expired or invalid
          await prefs.remove(_tokenKey);
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      SupabaseManager.logError('validate_session', e);
      emit(const AuthUnauthenticated());
    }
  }

  // Register a new company and CEO
  Future<void> register({
    required String username,
    required String password,
    required String companyName,
    required String ceoName,
  }) async {
    emit(const AuthLoading());
    try {
      if (DevModeManager.isDevMode) {
        // Dev Fallback Mode
        await Future.delayed(const Duration(milliseconds: 800));
        final mockUser = User(
          id: 'dev-user-uuid',
          username: username,
          companyName: companyName,
          ceoName: ceoName,
          cashBalance: 10000000.00,
          gameCurrentTime: DateTime.parse('2020-01-01T00:00:00Z'),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, 'mock-dev-token');
        emit(AuthAuthenticated(user: mockUser, token: 'mock-dev-token'));
        return;
      }

      // Call database DDL function
      final List<dynamic> response = await SupabaseManager.client.rpc(
        'register_company',
        params: {
          'p_username': username,
          'p_password': password,
          'p_company_name': companyName,
          'p_ceo_name': ceoName,
        },
      );

      if (response.isNotEmpty) {
        final result = response[0] as Map<String, dynamic>;
        final success = result['success'] as bool? ?? false;
        final message = result['message'] as String? ?? 'Registration failed';

        if (success) {
          // Auto login upon successful registration
          await login(username: username, password: password);
        } else {
          SupabaseManager.logRpcFailure('register_company', {
            'p_username': username,
            'p_company_name': companyName,
            'p_ceo_name': ceoName,
          }, message);
          emit(AuthError(message: message));
        }
      } else {
        const errorMsg = 'Invalid response from simulation server.';
        SupabaseManager.logRpcFailure('register_company', {
          'p_username': username,
          'p_company_name': companyName,
        }, errorMsg);
        emit(const AuthError(message: errorMsg));
      }
    } catch (e, stack) {
      SupabaseManager.logError('register_company', e, stack);
      emit(AuthError(message: e.toString()));
    }
  }

  // Login using custom username & hashed password check
  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      if (DevModeManager.isDevMode) {
        // Dev Fallback Mode
        await Future.delayed(const Duration(milliseconds: 800));
        final mockUser = User(
          id: 'dev-user-uuid',
          username: username,
          companyName: '$username Airlines',
          ceoName: 'CEO $username',
          cashBalance: 10000000.00,
          gameCurrentTime: DateTime.parse('2020-01-01T00:00:00Z'),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, 'mock-dev-token');
        emit(AuthAuthenticated(user: mockUser, token: 'mock-dev-token'));
        return;
      }

      final List<dynamic> response = await SupabaseManager.client.rpc(
        'login_company',
        params: {'p_username': username, 'p_password': password},
      );

      if (response.isNotEmpty) {
        final result = response[0] as Map<String, dynamic>;
        final success = result['success'] as bool? ?? false;
        final message = result['message'] as String? ?? 'Login failed';

        if (success) {
          final token = result['session_token'] as String;
          final user = User.fromMap(result);

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, token);

          emit(AuthAuthenticated(user: user, token: token));
        } else {
          SupabaseManager.logRpcFailure('login_company', {
            'p_username': username,
          }, message);
          emit(AuthError(message: message));
        }
      } else {
        const errorMsg = 'Invalid server response.';
        SupabaseManager.logRpcFailure('login_company', {
          'p_username': username,
        }, errorMsg);
        emit(const AuthError(message: errorMsg));
      }
    } catch (e, stack) {
      SupabaseManager.logError('login_company', e, stack);
      emit(AuthError(message: e.toString()));
    }
  }

  // Logout and destroy session locally
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (e) {
      SupabaseManager.logError('logout', e);
    }
    emit(const AuthUnauthenticated());
  }

  // Clear auth error state (e.g. when user navigates/resets input fields)
  void clearError() {
    if (state is AuthError) {
      emit(const AuthUnauthenticated());
    }
  }

  // Local helper to update user object in active memory (e.g. when cash balance changes)
  void updateActiveUser(User updatedUser) {
    if (state is AuthAuthenticated) {
      final currentToken = (state as AuthAuthenticated).token;
      emit(AuthAuthenticated(user: updatedUser, token: currentToken));
    }
  }

  // Dev mode bypass helper
  void _devFallbackLogin(String token) {
    final mockUser = User(
      id: 'dev-user-uuid',
      username: 'devmode',
      companyName: 'Skyward Star Airlines',
      ceoName: 'Fredianto',
      cashBalance: 10000000.00,
      gameCurrentTime: DateTime.parse('2020-01-01T00:00:00Z'),
    );
    emit(AuthAuthenticated(user: mockUser, token: token));
  }
}
