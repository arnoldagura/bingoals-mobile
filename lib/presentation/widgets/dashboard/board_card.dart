import 'package:flutter/material.dart';
import '../../../core/constants/board_categories.dart';
import '../../../data/models/models.dart';

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

  Color _accentColor(BuildContext context) {
    final cat = BoardCategory.fromKey(widget.board.category);
    if (cat != null) return cat.color;
    return Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final board = widget.board;
    final accent = _accentColor(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTap: () {
          _scaleController.forward().then((_) {
            _scaleController.reverse();
            widget.onTap?.call();
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surface.withValues(alpha: 0.9)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left accent border
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                // Card content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: title + badges
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title row with more menu
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      board.title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
                                        height: 1.2,
                                        letterSpacing: -0.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_horiz,
                                        size: 18,
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.4),
                                      ),
                                      padding: EdgeInsets.zero,
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
                                              Icon(Icons.edit_outlined,
                                                  size: 18),
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
                                                Icon(Icons.star_outline,
                                                    size: 18),
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
                                                  size: 18,
                                                  color:
                                                      colorScheme.error),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                    color:
                                                        colorScheme.error),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Year chip
                              Text(
                                '${board.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              // Bottom badges row
                              Row(
                                children: [
                                  // Solo / Shared badge
                                  _Badge(
                                    label: board.isShared
                                        ? 'Shared · ${board.memberCount}'
                                        : 'Solo',
                                    icon: board.isShared
                                        ? Icons.group_outlined
                                        : Icons.person_outline,
                                    color: accent,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Right: progress ring + dot grid
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _CompactProgressRing(
                              progress: board.progressPercent,
                              color: accent,
                            ),
                            const SizedBox(height: 10),
                            _MiniGridPreview(
                              completedPositions: board.completedPositions,
                              gridSize: board.gridSize,
                              accentColor: accent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _Badge({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactProgressRing extends StatelessWidget {
  final int progress;
  final Color color;

  const _CompactProgressRing({
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: 4,
            backgroundColor: color.withValues(alpha: isDark ? 0.15 : 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
          Text(
            '$progress%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGridPreview extends StatelessWidget {
  final List<int> completedPositions;
  final int gridSize;
  final Color accentColor;

  const _MiniGridPreview({
    required this.completedPositions,
    required this.gridSize,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedSet = completedPositions.toSet();
    // Cap display at 5x5 to keep it compact regardless of grid size
    final displaySize = gridSize > 5 ? 5 : gridSize;

    return SizedBox(
      width: 56,
      height: 56,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: displaySize,
          mainAxisSpacing: 2.5,
          crossAxisSpacing: 2.5,
        ),
        itemCount: displaySize * displaySize,
        itemBuilder: (context, displayIndex) {
          // Map display index back to actual board position
          final displayRow = displayIndex ~/ displaySize;
          final displayCol = displayIndex % displaySize;
          final actualRow =
              gridSize > 5 ? (displayRow * gridSize ~/ displaySize) : displayRow;
          final actualCol =
              gridSize > 5 ? (displayCol * gridSize ~/ displaySize) : displayCol;
          final actualIndex = actualRow * gridSize + actualCol;

          // Check if this cell or any "covered" cells are completed
          bool isCompleted = false;
          if (gridSize > 5) {
            // For 7x7, each display cell covers ~1.4 actual cells — mark if any covered
            final rowStep = gridSize ~/ displaySize;
            final colStep = gridSize ~/ displaySize;
            outer:
            for (int r = actualRow; r < actualRow + rowStep && r < gridSize; r++) {
              for (int c = actualCol;
                  c < actualCol + colStep && c < gridSize;
                  c++) {
                if (completedSet.contains(r * gridSize + c)) {
                  isCompleted = true;
                  break outer;
                }
              }
            }
          } else {
            isCompleted = completedSet.contains(actualIndex);
          }

          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: isCompleted
                  ? (isDark
                      ? accentColor.withValues(alpha: 0.85)
                      : Colors.black87)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08)),
            ),
          );
        },
      ),
    );
  }
}
