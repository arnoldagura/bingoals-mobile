import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/api_constants.dart';

// Configure secure storage with platform-specific options
// Note: macOS may require code signing for keychain access
// For development, this configuration should work without signing
const _secureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  ),
  mOptions: MacOsOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
    // Use default keychain service name for macOS
  ),
);

/// Provides the secure storage instance
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return _secureStorage;
});

/// Provides the Dio HTTP client with auth interceptor
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(_AuthInterceptor(ref));

  return dio;
});

/// Interceptor that attaches JWT token to requests
class _AuthInterceptor extends Interceptor {
  final Ref _ref;

  _AuthInterceptor(this._ref);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login/register
    final path = options.path;
    if (path == ApiConstants.login || path == ApiConstants.register) {
      return handler.next(options);
    }

    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: ApiConstants.tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Let the caller handle errors — no auto-logout here
    // Auth provider will check for 401 and handle it
    handler.next(err);
  }
}
