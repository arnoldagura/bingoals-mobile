/// API endpoints and configuration constants
class ApiConstants {
  ApiConstants._();

  // Base URL - change this to your deployed API URL
  // For iOS simulator: use localhost
  // For Android emulator: use 10.0.2.2 instead of localhost
  static const String baseUrl = 'http://localhost:8080';

  // Auth endpoints
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String googleAuth = '/api/auth/google';
  static const String me = '/api/me';

  // Board endpoints
  static const String boards = '/api/boards';
  static String board(String id) => '/api/boards/$id';

  // Goal endpoints
  static String updateGoal(String boardId, int position) =>
      '/api/boards/$boardId/goals/$position';
  static String toggleGoal(String boardId, int position) =>
      '/api/boards/$boardId/goals/$position/toggle';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage keys
  static const String tokenKey = 'auth_token';

  // Google Sign-In (Web client ID — must match GOOGLE_CLIENT_ID in api/.env)
  static const String googleServerClientId = '656331294595-huh2kgj7go6770uh1ueti0bqm63th7tj.apps.googleusercontent.com';
}
