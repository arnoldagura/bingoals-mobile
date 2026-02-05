import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../router/app_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Logo and welcome text
              Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      size: 48,
                      color: AppColors.gold,
                    ),
                  ).animate().fadeIn(duration: 600.ms).scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                      ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to Bingoals',
                    style: AppTypography.headlineLarge,
                    textAlign: TextAlign.center,
                  ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 12),
                  Text(
                    'Transform your annual goals into an engaging bingo game. Track progress, celebrate milestones, and make goal-setting fun.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate(delay: 400.ms).fadeIn(),
                ],
              ),
              const Spacer(),
              // Google Sign In Button
              _GoogleSignInButton(
                onPressed: () {
                  // TODO: Implement Google Sign In
                  context.go(AppRoutes.dashboard);
                },
              ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.3, end: 0),
              const SizedBox(height: 16),
              // Terms and Privacy
              Text(
                'By continuing, you agree to our Terms of Service and Privacy Policy',
                style: AppTypography.caption,
                textAlign: TextAlign.center,
              ).animate(delay: 800.ms).fadeIn(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.cardBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google logo placeholder
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with Google',
              style: AppTypography.button.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
