import 'package:logger/logger.dart';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../models/user.dart';
import 'api_client.dart';
var logger = Logger();
/// Auth response from login/register
class AuthResponse {
  final String token;
  final User user;

  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Auth API service
final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {'name': name, 'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    logger.t("Trace log");
    final response = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(response.data);
  }

  Future<User> getMe() async {
    final response = await _dio.get(ApiConstants.me);
    return User.fromJson(response.data);
  }
}
