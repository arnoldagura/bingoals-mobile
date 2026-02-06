import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'bingo_cell.dart';
import 'bingo_header.dart';

/// Center cell index (grace/free space)
const int graceCellIndex = 12;

/// Model for a goal in the bingo grid
class BingoGoal {
  final String? title;
  final bool isCompleted;

  const BingoGoal({this.title, this.isCompleted = false});

  bool get isEmpty => title == null || title!.isEmpty;
}

/// Main BINGO grid widget - 5x5 grid with header
class BingoGrid extends StatelessWidget {
  final List<BingoGoal> goals;
  final Function(int index)? onCellTap;

  const BingoGrid({
    super.key,
    required this.goals,
    this.onCellTap,
  }) : assert(goals.length == 25, 'Goals list must contain exactly 25 items');

  /// Creates an empty grid with 25 empty goals
  factory BingoGrid.empty({Function(int index)? onCellTap}) {
    return BingoGrid(
      goals: List.generate(25, (_) => const BingoGoal()),
      onCellTap: onCellTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bingoCell,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // BINGO header row
            const BingoHeader(),
            // 5x5 grid of cells
            _buildGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return AspectRatio(
      aspectRatio: 1,
      child: Column(
        children: List.generate(5, (row) {
          return Expanded(
            child: Row(
              children: List.generate(5, (col) {
                final index = row * 5 + col;
                final goal = goals[index];
                final isGrace = index == graceCellIndex;

                return Expanded(
                  child: BingoCell(
                    index: index,
                    goalTitle: goal.title,
                    isCompleted: goal.isCompleted,
                    isGrace: isGrace,
                    onTap: isGrace
                        ? null // Grace cell is not tappable
                        : (onCellTap != null ? () => onCellTap!(index) : null),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  /// Get completion statistics (excluding grace cell)
  int get completedCount => goals
      .asMap()
      .entries
      .where((e) => e.key != graceCellIndex && e.value.isCompleted)
      .length;

  int get filledCount => goals
      .asMap()
      .entries
      .where((e) => e.key != graceCellIndex && !e.value.isEmpty)
      .length;

  int get totalCount => 24; // 25 - 1 grace cell

  double get completionPercentage =>
      totalCount > 0 ? (completedCount / totalCount) * 100 : 0;
}
