/// API endpoints and configuration constants
class ApiConstants {
  ApiConstants._();

  // Base URL - change this to your deployed API URL
  // For iOS simulator: use localhost
  // For Android emulator: use 10.0.2.2 instead of localhost
  static const String baseUrl = 'http://localhost:8080';

  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String googleAuth = '/api/auth/google';
  static const String me = '/api/me';

  static const String boards = '/api/boards';
  static String board(String id) => '/api/boards/$id';

  static String updateGoal(String boardId, int position) =>
      '/api/boards/$boardId/goals/$position';
  static String toggleGoal(String boardId, int position) =>
      '/api/boards/$boardId/goals/$position/toggle';

  static String miniGoals(String boardId, int position) =>
      '/api/boards/$boardId/goals/$position/mini-goals';
  static String miniGoal(String boardId, int position, String miniGoalId) =>
      '/api/boards/$boardId/goals/$position/mini-goals/$miniGoalId';
  static String toggleMiniGoal(
          String boardId, int position, String miniGoalId) =>
      '/api/boards/$boardId/goals/$position/mini-goals/$miniGoalId/toggle';

  static String reflection(String boardId, int position) =>
      '/api/boards/$boardId/goals/$position/reflection';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String tokenKey = 'auth_token';

  static const String googleServerClientId = '656331294595-huh2kgj7go6770uh1ueti0bqm63th7tj.apps.googleusercontent.com';
}
