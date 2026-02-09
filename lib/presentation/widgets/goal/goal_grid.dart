import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.goalCell,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 1,
          child: Column(
            children: List.generate(gridSize, (row) {
              return Expanded(
                child: Row(
                  children: List.generate(gridSize, (col) {
                    final index = row * gridSize + col;
                    final goal = goals[index];

                    return Expanded(
                      child: GoalCell(
                        index: index,
                        goalTitle: goal.title,
                        status: goal.status,
                        isGraceSquare: goal.isGraceSquare,
                        progress: goal.progress,
                        onTap: goal.isGraceSquare
                            ? null
                            : (onCellTap != null
                                ? () => onCellTap!(index)
                                : null),
                        onLongPress: goal.isGraceSquare
                            ? null
                            : (onCellLongPress != null
                                ? () => onCellLongPress!(index)
                                : null),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  int get completedCount =>
      goals.where((g) => g.isCompleted && !g.isGraceSquare).length;

  int get filledCount =>
      goals.where((g) => !g.isEmpty && !g.isGraceSquare).length;

  int get totalCount => goals.length;

  double get completionPercentage =>
      filledCount > 0 ? (completedCount / filledCount) * 100 : 0;
}
