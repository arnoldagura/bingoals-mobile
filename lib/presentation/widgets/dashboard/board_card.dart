import 'package:flutter/material.dart';
import '../../../core/constants/board_categories.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/models.dart';
import '../common/glass_card.dart';
import '../common/circular_progress.dart';

class BoardCard extends StatefulWidget {
  final BoardSummary board;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;

  const BoardCard({
    super.key,
    required this.board,
    this.onTap,
    this.onRename,
    this.onDelete,
    this.onSetDefault,
  });

  @override
  State<BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<BoardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.easeInOut,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final board = widget.board;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GlassCard(
      onTap: () {
        _scaleController.forward().then((_) {
          _scaleController.reverse();
          widget.onTap?.call();
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              board.title,
                              style: AppTypography.headlineSmall.copyWith(
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (board.isShared) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.group,
                                      size: 12,
                                      color: colorScheme.tertiary),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${board.memberCount}',
                                    style: AppTypography.caption.copyWith(
                                      color: colorScheme.tertiary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (board.isDefault) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.star,
                              size: 16,
                              color: colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'rename':
                            widget.onRename?.call();
                            break;
                          case 'default':
                            widget.onSetDefault?.call();
                            break;
                          case 'delete':
                            widget.onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Rename'),
                            ],
                          ),
                        ),
                        if (!board.isDefault)
                          const PopupMenuItem(
                            value: 'default',
                            child: Row(
                              children: [
                                Icon(Icons.star_outline, size: 18),
                                SizedBox(width: 8),
                                Text('Set as default'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: colorScheme.error),
                                const SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: colorScheme.error)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (board.category != null) ...[
                  const SizedBox(height: 6),
                  Builder(builder: (context) {
                    final cat =
                        BoardCategory.fromKey(board.category);
                    if (cat == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 12, color: cat.color),
                          const SizedBox(width: 4),
                          Text(
                            cat.label,
                            style: AppTypography.caption.copyWith(
                              color: cat.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 4),
                Text(
                  '${board.completedCount} of ${board.goalCount} goals complete',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircularProgress(
                      progress: board.progressPercent,
                      size: 70,
                      strokeWidth: 5,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Hero(
                        tag: 'board-grid-${board.id}',
                        child: _MiniGridPreview(
                          completed: board.completedCount,
                          gridSize: board.gridSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.03),
              border: Border(
                top: BorderSide(
                  color: colorScheme.onSurface.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Open Board',
                  style: AppTypography.labelMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _MiniGridPreview extends StatelessWidget {
  final int completed;
  final int gridSize;

  const _MiniGridPreview({
    required this.completed,
    required this.gridSize
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridSize,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: gridSize * gridSize,
          itemBuilder: (context, index) {
            final isCompleted = index < completed;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isCompleted
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            );
          },
        ),
      ),
    );
  }
}
