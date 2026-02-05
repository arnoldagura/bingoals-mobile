import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../router/app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      // TODO: Check auth state and navigate accordingly
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icon placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                size: 60,
                color: AppColors.gold,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            const SizedBox(height: 24),
            // App name
            Text(
              'Bingoals',
              style: AppTypography.displayMedium.copyWith(
                color: AppColors.gold,
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            // Tagline
            Text(
              'Track your goals, celebrate your wins',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 600.ms),
            const SizedBox(height: 48),
            // Loading indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gold.withValues(alpha: 0.5),
              ),
            ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
