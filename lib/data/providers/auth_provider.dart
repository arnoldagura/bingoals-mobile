import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../models/user.dart';

/// Auth state
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

  /// Try to restore session from stored token
  Future<void> tryRestoreSession() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: ApiConstants.tokenKey);
    if (token == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final authApi = _ref.read(authApiProvider);
      final user = await authApi.getMe();
      state = AuthState(user: user);
    } on DioException catch (e) {
      // Token is invalid or expired — clear it
      if (e.response?.statusCode == 401) {
        await storage.delete(key: ApiConstants.tokenKey);
      }
      state = const AuthState();
    } catch (_) {
      state = const AuthState();
    }
  }

  /// Register a new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authApi = _ref.read(authApiProvider);
      final response = await authApi.register(
        name: name,
        email: email,
        password: password,
      );
      await _saveTokenAndSetUser(response.token, response.user);
      return true;
    } on DioException catch (e) {
      final message = _extractError(e);
      state = AuthState(error: message);
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authApi = _ref.read(authApiProvider);
      final response = await authApi.login(email: email, password: password);
      await _saveTokenAndSetUser(response.token, response.user);
      return true;
    } on DioException catch (e) {
      final message = _extractError(e);
      state = AuthState(error: message);
      return false;
    }
  }

  /// Logout — clear token and state
  Future<void> logout() async {
    final storage = _ref.read(secureStorageProvider);
    await storage.delete(key: ApiConstants.tokenKey);
    state = const AuthState();
  }

  Future<void> _saveTokenAndSetUser(String token, User user) async {
    final storage = _ref.read(secureStorageProvider);
    await storage.write(key: ApiConstants.tokenKey, value: token);
    state = AuthState(user: user);
  }

  String _extractError(DioException e) {
    if (e.response?.data is Map) {
      return (e.response!.data as Map)['error'] as String? ??
          'Something went wrong';
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server';
    }
    return 'Something went wrong';
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
