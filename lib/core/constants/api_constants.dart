/// API endpoints and configuration constants
class ApiConstants {
  ApiConstants._();

  // Base URL - change this to your deployed API URL
  // For local development, use your machine's IP address instead of localhost
  // e.g., 'http://192.168.1.100:3000' for iOS simulator/Android emulator
  static const String baseUrl = 'http://localhost:3000';

  // API endpoints
  static const String board = '/api/board';
  static const String goals = '/api/board/goals';
  static const String narrative = '/api/ai/narrative';

  // Auth endpoints (to be created for mobile)
  static const String authMobileGoogle = '/api/auth/mobile/google';
  static const String authRefresh = '/api/auth/mobile/refresh';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static const String authHeader = 'Authorization';
  static const String contentType = 'application/json';
}
