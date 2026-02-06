import 'package:flutter/material.dart';
import '../../../core/theme/typography.dart';
import '../../../data/providers/boards_provider.dart';
import '../common/glass_card.dart';

/// Dashboard stats grid showing goals, progress, gems, and boards
class DashboardStatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const DashboardStatsGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          icon: Icons.check_circle_outline,
          label: 'Goals Complete',
          value: '${stats.completedGoals}',
          subValue: 'of ${stats.totalGoals}',
        ),
        _StatCard(
          icon: Icons.trending_up,
          label: 'Overall Progress',
          value: '${stats.overallProgress}%',
        ),
        _StatCard(
          icon: Icons.diamond_outlined,
          label: 'Gems Earned',
          value: '${stats.totalGems}',
        ),
        _StatCard(
          icon: Icons.calendar_today_outlined,
          label: 'Active Boards',
          value: '${stats.activeBoards}',
          subValue: 'in ${stats.year}',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subValue;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    letterSpacing: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(width: 6),
                Text(
                  subValue!,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
