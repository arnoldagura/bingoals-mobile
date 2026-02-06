import 'package:flutter/material.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/models.dart';
import '../common/glass_card.dart';
import '../common/circular_progress.dart';

/// Card displaying a board summary with mini grid preview
class BoardCard extends StatelessWidget {
  final BoardSummary board;
  final VoidCallback? onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;
  final int totalBoards;

  const BoardCard({
    super.key,
    required this.board,
    this.onTap,
    this.onRename,
    this.onDelete,
    this.onSetDefault,
    this.totalBoards = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                    // Menu button
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_horiz,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'rename':
                            onRename?.call();
                            break;
                          case 'default':
                            onSetDefault?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
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
                        if (totalBoards > 1)
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
                const SizedBox(height: 4),
                Text(
                  '${board.completedCount} of ${board.goalCount} goals complete',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                // Progress and mini grid
                Row(
                  children: [
                    CircularProgress(
                      progress: board.progressPercent,
                      size: 70,
                      strokeWidth: 5,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _MiniGridPreview(
                        completed: board.completedCount,
                        total: 25,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Footer
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
    );
  }
}

/// Mini 5x5 grid preview showing completed goals
class _MiniGridPreview extends StatelessWidget {
  final int completed;
  final int total;

  const _MiniGridPreview({
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: 25,
          itemBuilder: (context, index) {
            final isCenter = index == 12; // Center cell (grace/free space)
            final isCompleted = index < completed && !isCenter;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: isCenter
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary.withValues(alpha: 0.4),
                          colorScheme.secondary.withValues(alpha: 0.3),
                        ],
                      )
                    : null,
                color: isCenter
                    ? null
                    : isCompleted
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
