import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/api_constants.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../models/user.dart';
import 'boards_provider.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';

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

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState());

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
      if (e.response?.statusCode == 401) {
        await storage.delete(key: ApiConstants.tokenKey);
      }
      state = const AuthState();
    } catch (_) {
      state = const AuthState();
    }
  }

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

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(error: null);
    try {
      final googleSignIn = GoogleSignIn.instance;
      await googleSignIn.initialize(
        serverClientId: ApiConstants.googleServerClientId,
      );
      final account = await googleSignIn.authenticate();

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        state = AuthState(error: 'Failed to get Google ID token');
        return false;
      }

      final authApi = _ref.read(authApiProvider);
      final response = await authApi.googleLogin(idToken: idToken);
      await _saveTokenAndSetUser(response.token, response.user);
      return true;
    } on DioException catch (e) {
      final message = _extractError(e);
      state = AuthState(error: message);
      return false;
    } catch (e) {
      state = AuthState(error: 'Google sign-in failed');
      return false;
    }
  }

  Future<void> refreshUser() async {
    try {
      final authApi = _ref.read(authApiProvider);
      final user = await authApi.getMe();
      state = AuthState(user: user);
    } catch (_) {
    }
  }

  Future<void> logout() async {
    final storage = _ref.read(secureStorageProvider);
    await storage.delete(key: ApiConstants.tokenKey);
    _ref.invalidate(boardSummariesProvider);
    _ref.invalidate(onboardingCompletedProvider);
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
