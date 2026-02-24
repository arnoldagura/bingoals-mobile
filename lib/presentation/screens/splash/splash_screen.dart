import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/typography.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/common/gradient_mesh_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Skip delay on web — auth restores from cache instantly and the user
    // shouldn't have to wait 1.5s on every page refresh.
    if (!kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    if (!mounted) return;
    // This triggers router redirect via auth state change
    await ref.read(authProvider.notifier).tryRestoreSession();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GradientMeshScaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.grid_view_rounded,
                size: 60,
                color: colorScheme.primary,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            const SizedBox(height: 24),
            Text(
              'Bingoals',
              style: AppTypography.displayMedium.copyWith(
                color: colorScheme.primary,
              ),
            )
                .animate(delay: 300.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text(
              'Track your goals, celebrate your wins',
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 600.ms),
            const SizedBox(height: 48),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary.withValues(alpha: 0.5),
              ),
            ).animate(delay: 800.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
