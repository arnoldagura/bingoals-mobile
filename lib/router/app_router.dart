import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers/auth_provider.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/login/login_screen.dart';
import '../presentation/screens/login/register_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/dashboard/dashboard_screen.dart';
import '../presentation/screens/board/board_screen.dart';
import '../presentation/screens/journal/journal_screen.dart';
import '../presentation/screens/notifications/notifications_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/vision_board/vision_board_screen.dart';
import '../presentation/widgets/common/main_shell.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/';
  static const String board = '/board/:boardId';
  static const String visionBoard = '/vision-board';
  static const String journal = '/journal';
  static const String notifications = '/notifications';
  static const String settings = '/settings';

  static String boardPath(String boardId) => '/board/$boardId';
}

class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();

  ref.listen(authProvider, (_, _) => refreshNotifier.notify());
  ref.listen(onboardingCompletedProvider, (_, _) => refreshNotifier.notify());

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final onboardingDone =
          ref.read(onboardingCompletedProvider).valueOrNull ?? true;

      final isLoggedIn = authState.isLoggedIn;
      final isInitializing = authState.isInitializing;
      final currentPath = state.uri.path;

      // Still determining auth state — always show splash
      if (isInitializing) {
        return currentPath == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAuthPage =
          currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register ||
          currentPath == AppRoutes.splash;

      if (!isLoggedIn && !isAuthPage) {
        return AppRoutes.login;
      }

      if (!isLoggedIn && currentPath == AppRoutes.splash) {
        return AppRoutes.login;
      }

      if (isLoggedIn && isAuthPage) {
        return onboardingDone ? AppRoutes.dashboard : AppRoutes.onboarding;
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
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Board detail — full screen, no bottom nav
      GoRoute(
        path: '/board/:boardId',
        name: 'board',
        builder: (context, state) {
          final boardId = state.pathParameters['boardId']!;
          return BoardScreen(boardId: boardId);
        },
      ),
      // Main shell — persistent bottom nav for the 4 tabs
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.visionBoard,
            name: 'visionBoard',
            builder: (context, state) => const VisionBoardScreen(),
          ),
          GoRoute(
            path: AppRoutes.journal,
            name: 'journal',
            builder: (context, state) => const JournalScreen(),
          ),
          GoRoute(
            path: AppRoutes.notifications,
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  );
});
