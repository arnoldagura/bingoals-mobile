import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';

class VisionBoardScreen extends StatelessWidget {
  const VisionBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Vision Board', style: AppTypography.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: Export/share vision board
            },
            tooltip: 'Share',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.collections_outlined,
                size: 64,
                color: AppColors.gold.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No completed goals yet',
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete goals to see them displayed here as beautiful polaroid-style cards.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
