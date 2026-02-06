import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers/auth_provider.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/login/login_screen.dart';
import '../presentation/screens/login/register_screen.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/board/board_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/vision_board/vision_board_screen.dart';

/// Route names
class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/';
  static const String board = '/board/:boardId';
  static const String visionBoard = '/vision-board';
  static const String settings = '/settings';

  /// Helper to build board route with ID
  static String boardPath(String boardId) => '/board/$boardId';
}

/// GoRouter configuration provider
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isLoading = authState.isLoading;
      final currentPath = state.uri.path;

      // While loading (checking stored token), stay on splash
      if (isLoading && currentPath == AppRoutes.splash) {
        return null;
      }

      // Done loading, not logged in, on splash → go to login
      if (!isLoading && !isLoggedIn && currentPath == AppRoutes.splash) {
        return AppRoutes.login;
      }

      final isAuthPage = currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register ||
          currentPath == AppRoutes.splash;

      // Not logged in → go to login
      if (!isLoggedIn && !isAuthPage) {
        return AppRoutes.login;
      }

      // Logged in but on auth page → go to dashboard
      if (isLoggedIn && isAuthPage) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/board/:boardId',
        name: 'board',
        builder: (context, state) {
          final boardId = state.pathParameters['boardId']!;
          return BoardScreen(boardId: boardId);
        },
      ),
      GoRoute(
        path: AppRoutes.visionBoard,
        name: 'visionBoard',
        builder: (context, state) => const VisionBoardScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
