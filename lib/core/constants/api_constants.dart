/// API endpoints and configuration constants
class ApiConstants {
  ApiConstants._();

  // Base URL - change this to your deployed API URL
  // For iOS simulator: use localhost
  // For Android emulator: use 10.0.2.2 instead of localhost
  // Remote: 'https://bingoal-api.onrender.com'
  // Local:  'http://localhost:8080'
  static const String baseUrl = 'https://bingoal-api.onrender.com';

  /// WebSocket base URL (derived from baseUrl)
  static String get wsBaseUrl {
    final uri = Uri.parse(baseUrl);
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '$scheme://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  static String boardWebSocket(String boardId) => '/ws/boards/$boardId';

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

  // Board invites & members
  static String boardInvites(String boardId) => '/api/boards/$boardId/invites';
  static String joinInvite(String code) => '/api/invites/$code/join';
  static String boardMembers(String boardId) => '/api/boards/$boardId/members';
  static String removeMember(String boardId, String userId) =>
      '/api/boards/$boardId/members/$userId';
  static String leaveBoard(String boardId) => '/api/boards/$boardId/leave';

  // Board activity
  static String boardActivity(String boardId) =>
      '/api/boards/$boardId/activity';

  // Goal reactions
  static String goalReactions(String goalId) => '/api/goals/$goalId/reactions';

  // Goal comments
  static String goalComments(String goalId) => '/api/goals/$goalId/comments';
  static String deleteComment(String goalId, String commentId) =>
      '/api/goals/$goalId/comments/$commentId';

  // Notifications
  static const String notifications = '/api/notifications';
  static String markNotificationRead(String id) =>
      '/api/notifications/$id/read';
  static const String markAllNotificationsRead = '/api/notifications/read-all';

  // User profiles
  static String userProfile(String userId) => '/api/users/$userId';

  // Device token for push notifications
  static const String deviceToken = '/api/device-token';

  static const String upload = '/api/upload';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String tokenKey = 'auth_token';

  static const String googleServerClientId = '656331294595-huh2kgj7go6770uh1ueti0bqm63th7tj.apps.googleusercontent.com';
}
