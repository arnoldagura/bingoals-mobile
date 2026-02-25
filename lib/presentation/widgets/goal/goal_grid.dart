import 'package:flutter/material.dart';
import '../../../data/models/goal.dart';
import 'goal_cell.dart';

class GoalGrid extends StatelessWidget {
  final List<Goal> goals;
  final int gridSize;
  final Function(int index)? onCellTap;
  final Function(int index)? onCellLongPress;

  const GoalGrid({
    super.key,
    required this.goals,
    required this.gridSize,
    this.onCellTap,
    this.onCellLongPress,
  });

  static const double _gap = 4.0;
  static const double _cellRadius = 10.0;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        spacing: _gap,
        children: List.generate(gridSize, (row) {
          return Expanded(
            child: Row(
              spacing: _gap,
              children: List.generate(gridSize, (col) {
                final index = row * gridSize + col;
                final goal = goals[index];

                return Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_cellRadius),
                    child: GoalCell(
                      index: index,
                      goalTitle: goal.title,
                      status: goal.status,
                      progress: goal.progress,
                      icon: goal.icon,
                      imageUrl: goal.memories
                              .where((m) => m.isBoardImage)
                              .firstOrNull
                              ?.imageUrl ??
                          goal.imageUrl,
                      commentCount: goal.commentCount,
                      onTap: onCellTap != null
                          ? () => onCellTap!(index)
                          : null,
                      onLongPress: onCellLongPress != null
                          ? () => onCellLongPress!(index)
                          : null,
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  int get completedCount =>
      goals.where((g) => g.isCompleted).length;

  int get filledCount =>
      goals.where((g) => !g.isEmpty).length;

  int get totalCount => goals.length;

  double get completionPercentage =>
      totalCount > 0 ? (completedCount / totalCount) * 100 : 0;
}
