import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyward/core/database/supabase_client.dart';
import 'package:skyward/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:skyward/features/auth/presentation/cubit/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Robust handwritten Fake classes to bypass Mocktail generic method constraints
class FakeSupabaseClient implements SupabaseClient {
  final FutureOr<dynamic> Function(String fn, Map<String, dynamic>? params) onRpc;

  FakeSupabaseClient({required this.onRpc});

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    int? count,
    dynamic get,
  }) {
    return FakePostgrestFilterBuilder<T>(
      fn: fn,
      params: params,
      onRpc: onRpc,
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePostgrestFilterBuilder<T> implements PostgrestFilterBuilder<T> {
  final String fn;
  final Map<String, dynamic>? params;
  final FutureOr<dynamic> Function(String fn, Map<String, dynamic>? params) onRpc;

  FakePostgrestFilterBuilder({
    required this.fn,
    required this.params,
    required this.onRpc,
  });

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function? onError}) async {
    try {
      final dynamic result = await onRpc(fn, params);
      return await onValue(result as T);
    } catch (e, stack) {
      if (onError != null) {
        return await onError(e, stack) as R;
      }
      rethrow;
    }
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Layer 3 Auth Integration Tests', () {
    late AuthCubit authCubit;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      // Ensure supabaseUrl is NOT the placeholder 'YOUR_SUPABASE_URL' to force database calls
      SupabaseManager.supabaseUrl = 'https://REDACTED_PROJECT_ID.supabase.co';
    });

    tearDown(() {
      authCubit.close();
      SupabaseManager.mockClient = null;
    });

    test('Successful Login through RPC returns AuthAuthenticated', () async {
      final mockResponse = [
        {
          'success': true,
          'session_token': 'integration-test-session-token-123',
          'id': 'user-123',
          'username': 'pilot1',
          'company_name': 'Pilot Airways',
          'ceo_name': 'Cap. Pilot',
          'cash_balance': 50000000.0,
          'game_current_time': '2026-05-30T12:00:00Z',
        }
      ];

      final fakeClient = FakeSupabaseClient(
        onRpc: (fn, params) {
          expect(fn, 'login_company');
          expect(params?['p_username'], 'pilot1');
          return mockResponse;
        },
      );
      SupabaseManager.mockClient = fakeClient;
      authCubit = AuthCubit();

      final expectedStates = [
        isA<AuthAuthenticated>().having(
          (a) => a.token,
          'token',
          'integration-test-session-token-123',
        ).having(
          (a) => a.user.companyName,
          'companyName',
          'Pilot Airways',
        ),
      ];

      expectLater(authCubit.stream, emitsInOrder(expectedStates));

      await authCubit.login(username: 'pilot1', password: 'password123');

      // Verify SharedPreferences persisted the token
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('skyward_session_token'), 'integration-test-session-token-123');
    });

    test('Failed Login through RPC returns AuthError', () async {
      final mockResponse = [
        {
          'success': false,
          'message': 'Invalid credentials or company bankrupt',
        }
      ];

      final fakeClient = FakeSupabaseClient(
        onRpc: (fn, params) {
          return mockResponse;
        },
      );
      SupabaseManager.mockClient = fakeClient;
      authCubit = AuthCubit();

      final expectedStates = [
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          'Invalid credentials or company bankrupt',
        ),
      ];

      expectLater(authCubit.stream, emitsInOrder(expectedStates));

      await authCubit.login(username: 'failed_pilot', password: 'wrongpassword');
    });

    test('Auto login with existing valid token restores session', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('skyward_session_token', 'valid-active-token');

      final mockResponse = [
        {
          'success': true,
          'id': 'user-123',
          'username': 'pilot1',
          'company_name': 'Pilot Airways',
          'ceo_name': 'Cap. Pilot',
          'cash_balance': 50000000.0,
          'game_current_time': '2026-05-30T12:00:00Z',
        }
      ];

      final fakeClient = FakeSupabaseClient(
        onRpc: (fn, params) {
          expect(fn, 'validate_session');
          expect(params?['p_token'], 'valid-active-token');
          return mockResponse;
        },
      );
      SupabaseManager.mockClient = fakeClient;
      authCubit = AuthCubit();

      final expectedStates = [
        const AuthLoading(),
        isA<AuthAuthenticated>().having(
          (a) => a.token,
          'token',
          'valid-active-token',
        ),
      ];

      expectLater(authCubit.stream, emitsInOrder(expectedStates));

      await authCubit.autoLogin();
    });

    test('Auto login with expired token clears storage and emits Unauthenticated', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('skyward_session_token', 'expired-token');

      final mockResponse = [
        {
          'success': false,
          'message': 'Session expired',
        }
      ];

      final fakeClient = FakeSupabaseClient(
        onRpc: (fn, params) {
          return mockResponse;
        },
      );
      SupabaseManager.mockClient = fakeClient;
      authCubit = AuthCubit();

      final expectedStates = [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ];

      expectLater(authCubit.stream, emitsInOrder(expectedStates));

      await authCubit.autoLogin();

      // Verify token cleared
      expect(prefs.getString('skyward_session_token'), isNull);
    });

    test('RPC Exceptions (e.g. database timeout or RLS block) emits AuthError', () async {
      final fakeClient = FakeSupabaseClient(
        onRpc: (fn, params) {
          throw const PostgrestException(
            message: 'Database query execution timeout or RLS policies check failed.',
          );
        },
      );
      SupabaseManager.mockClient = fakeClient;
      authCubit = AuthCubit();

      final expectedStates = [
        isA<AuthError>().having(
          (e) => e.message,
          'message',
          contains('Database query execution timeout'),
        ),
      ];

      expectLater(authCubit.stream, emitsInOrder(expectedStates));

      await authCubit.login(username: 'timeout_user', password: 'pwd');
    });
  });
}
