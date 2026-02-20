import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/typography.dart';
import '../../../data/providers/boards_provider.dart';
import '../common/glass_card.dart';

class DashboardStatsGrid extends StatelessWidget {
  final DashboardStats stats;

  const DashboardStatsGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Full-width hero card: Goals Complete with progress ring
        _HeroStatCard(
          completedGoals: stats.completedGoals,
          totalGoals: stats.totalGoals,
          overallProgress: stats.overallProgress,
        ),
        const SizedBox(height: 12),
        // Three smaller cards in a row
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: stats.dailyStreak,
                suffix: stats.dailyStreak == 1 ? 'day' : 'days',
                showFlame: stats.dailyStreak > 0,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStatCard(
                icon: Icons.diamond_outlined,
                label: 'Gems',
                value: stats.totalGems,
                suffix: stats.level,
                showSparkle: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniStatCard(
                icon: Icons.dashboard_outlined,
                label: 'Boards',
                value: stats.activeBoards,
                suffix: 'active',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Full-width card with large progress ring and animated counter
class _HeroStatCard extends StatelessWidget {
  final int completedGoals;
  final int totalGoals;
  final int overallProgress;

  const _HeroStatCard({
    required this.completedGoals,
    required this.totalGoals,
    required this.overallProgress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Progress ring
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: CircularProgressIndicator(
                    value: totalGoals > 0 ? completedGoals / totalGoals : 0,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor:
                        colorScheme.onSurface.withValues(alpha: 0.08),
                    color: colorScheme.primary,
                  ),
                ),
                _AnimatedCounter(
                  value: overallProgress,
                  suffix: '%',
                  style: AppTypography.headlineMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOALS COMPLETE',
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    _AnimatedCounter(
                      value: completedGoals,
                      style: AppTypography.displaySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'of $totalGoals',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact stat card for the bottom row
class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final String? suffix;
  final bool showFlame;
  final bool showSparkle;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
    this.showFlame = false,
    this.showSparkle = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget iconWidget = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: colorScheme.primary),
    );

    // Pulsing flame for active streaks
    if (showFlame && value > 0) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.15, 1.15),
            duration: 800.ms,
            curve: Curves.easeInOut,
          );
    }

    // Subtle shimmer on gems
    if (showSparkle && value > 0) {
      iconWidget = iconWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 2000.ms,
            color: colorScheme.primary.withValues(alpha: 0.3),
          );
    }

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget,
          const SizedBox(height: 10),
          _AnimatedCounter(
            value: value,
            style: AppTypography.headlineMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            suffix ?? label,
            style: AppTypography.caption.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.45),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Animated counter that counts up from 0 to [value]
class _AnimatedCounter extends StatefulWidget {
  final int value;
  final String suffix;
  final TextStyle style;

  const _AnimatedCounter({
    required this.value,
    required this.style,
    this.suffix = '',
  });

  @override
  State<_AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<_AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _animation = Tween<double>(
        begin: _previousValue.toDouble(),
        end: widget.value.toDouble(),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) => Text(
        '${_animation.value.round()}${widget.suffix}',
        style: widget.style,
      ),
    );
  }
}
