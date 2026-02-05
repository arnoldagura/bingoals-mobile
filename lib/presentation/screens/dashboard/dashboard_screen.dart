import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/helpers.dart';
import '../../../router/app_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${Helpers.currentYear} Goals',
          style: AppTypography.headlineMedium,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_agenda_outlined),
            onPressed: () => context.push(AppRoutes.visionBoard),
            tooltip: 'Vision Board',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats row
              _StatsRow(),
              const SizedBox(height: 24),
              // Bingo Grid placeholder
              Expanded(
                child: _BingoGridPlaceholder(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Completed',
            value: '0',
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'In Progress',
            value: '0',
            icon: Icons.pending_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Milestones',
            value: '0',
            icon: Icons.emoji_events_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _BingoGridPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const gridSize = 5;

    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridSize,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: gridSize * gridSize,
            itemBuilder: (context, index) {
              return _PlaceholderCell(position: index);
            },
          ),
        ),
      ),
    );
  }
}

class _PlaceholderCell extends StatelessWidget {
  final int position;

  const _PlaceholderCell({required this.position});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Open goal modal
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tapped cell $position')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.cardBorder,
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            color: AppColors.textMuted,
            size: 20,
          ),
        ),
      ),
    );
  }
}
