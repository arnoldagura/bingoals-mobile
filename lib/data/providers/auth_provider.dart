import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/api_constants.dart';
import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../api/notifications_api.dart';
import '../models/user.dart';
import '../services/push_service.dart';
import 'boards_provider.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final bool isInitializing;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isInitializing = true,
    this.error,
  });

  bool get isLoggedIn => user != null;

  AuthState copyWith({User? user, bool? isLoading, bool? isInitializing, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  StreamSubscription? _googleAuthSub;

  AuthNotifier(this._ref) : super(const AuthState()) {
    if (kIsWeb) _setupWebGoogleSignIn();
  }

  void _setupWebGoogleSignIn() {
    GoogleSignIn.instance.initialize();
    _googleAuthSub = GoogleSignIn.instance.authenticationEvents.listen(
      (event) async {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          state = state.copyWith(isLoading: true, error: null);
          try {
            final idToken = event.user.authentication.idToken;
            if (idToken == null) {
              state = AuthState(error: 'Failed to get Google ID token');
              return;
            }
            final authApi = _ref.read(authApiProvider);
            final response = await authApi.googleLogin(idToken: idToken);
            await _saveTokenAndSetUser(response.token, response.user);
          } on DioException catch (e) {
            state = AuthState(error: _extractError(e));
          } catch (e) {
            state = AuthState(error: e.toString());
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _googleAuthSub?.cancel();
    super.dispose();
  }

  Future<void> tryRestoreSession() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: ApiConstants.tokenKey);
    if (token == null) {
      // No token — definitively not logged in, done initializing
      state = const AuthState(isInitializing: false);
      return;
    }

    // Immediately restore from cached user JSON so the app doesn't log out
    // when the server is sleeping (Render.com free tier) or there's no network.
    final cachedUserJson = await storage.read(key: ApiConstants.userKey);
    if (cachedUserJson != null) {
      try {
        final user = User.fromJson(
            jsonDecode(cachedUserJson) as Map<String, dynamic>);
        state = AuthState(user: user, isInitializing: false);
      } catch (_) {
        // Corrupt cache — treat as not logged in, done initializing
        state = const AuthState(isInitializing: false);
      }
    } else {
      // Token but no cached user — done initializing, verify in background
      state = const AuthState(isInitializing: false, isLoading: true);
    }

    // Verify session in background — only log out on an explicit 401.
    try {
      final authApi = _ref.read(authApiProvider);
      final user = await authApi.getMe();
      await storage.write(
        key: ApiConstants.userKey,
        value: jsonEncode(user.toJson()),
      );
      state = AuthState(user: user, isInitializing: false);
      _registerDeviceToken();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token explicitly rejected — clear everything.
        await storage.delete(key: ApiConstants.tokenKey);
        await storage.delete(key: ApiConstants.userKey);
        state = const AuthState(isInitializing: false);
      }
      // Network errors / timeouts / server sleeping → keep the cached user.
    } catch (_) {
      // Unexpected errors → keep the cached user.
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
    if (kIsWeb) return false; // Web uses renderButton + authenticationEvents
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
      state = AuthState(error: e.toString());
      return false;
    }
  }

  Future<void> refreshUser() async {
    try {
      final authApi = _ref.read(authApiProvider);
      final user = await authApi.getMe();
      final storage = _ref.read(secureStorageProvider);
      await storage.write(
        key: ApiConstants.userKey,
        value: jsonEncode(user.toJson()),
      );
      state = AuthState(user: user);
    } catch (_) {}
  }

  Future<bool> updateProfile({
    String? name,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    try {
      final authApi = _ref.read(authApiProvider);
      final user = await authApi.updateProfile(
        name: name,
        displayName: displayName,
        avatarUrl: avatarUrl,
        bio: bio,
      );
      final storage = _ref.read(secureStorageProvider);
      await storage.write(
        key: ApiConstants.userKey,
        value: jsonEncode(user.toJson()),
      );
      state = AuthState(user: user);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      PushService.instance.setTokenRefreshCallback(null);
    } catch (_) {
      // Firebase may not be initialized — safe to ignore.
    }
    final storage = _ref.read(secureStorageProvider);
    await storage.delete(key: ApiConstants.tokenKey);
    await storage.delete(key: ApiConstants.userKey);
    _ref.invalidate(boardSummariesProvider);
    _ref.invalidate(onboardingCompletedProvider);
    state = const AuthState();
  }

  Future<void> _saveTokenAndSetUser(String token, User user) async {
    final storage = _ref.read(secureStorageProvider);
    await storage.write(key: ApiConstants.tokenKey, value: token);
    await storage.write(
      key: ApiConstants.userKey,
      value: jsonEncode(user.toJson()),
    );
    state = AuthState(user: user);
    _registerDeviceToken();
  }

  /// Sends FCM token to backend so push notifications reach this device.
  Future<void> _registerDeviceToken() async {
    try {
      final fcmToken = PushService.instance.fcmToken;
      if (fcmToken == null) return;
      final api = _ref.read(notificationsApiProvider);
      await api.registerDeviceToken(fcmToken);
      // Re-register if token refreshes while logged in
      PushService.instance.setTokenRefreshCallback((newToken) {
        _ref.read(notificationsApiProvider).registerDeviceToken(newToken);
      });
    } catch (_) {
      // Push registration is best-effort — don't block auth
    }
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
