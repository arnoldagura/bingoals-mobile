import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/typography.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/boards_provider.dart';
import '../../widgets/bingo/bingo_grid.dart';
import '../../widgets/common/gradient_mesh_background.dart';

/// View mode for the board
enum BoardViewMode { grid, vision }

class BoardScreen extends ConsumerStatefulWidget {
  final String boardId;

  const BoardScreen({super.key, required this.boardId});

  @override
  ConsumerState<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends ConsumerState<BoardScreen> {
  BoardViewMode _viewMode = BoardViewMode.grid;
  final _goalTitleController = TextEditingController();

  @override
  void dispose() {
    _goalTitleController.dispose();
    super.dispose();
  }

  void _showGoalDialog(Board board, int position) {
    final goal = board.goals[position];
    _goalTitleController.text = goal.title ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.isEmpty ? 'Add Goal' : 'Edit Goal',
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _goalTitleController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Enter your goal...',
                  labelText: 'Goal Title',
                ),
                onSubmitted: (_) => _saveGoal(position),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (!goal.isEmpty) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ref
                              .read(boardActionsProvider)
                              .toggleGoalCompletion(widget.boardId, position);
                        },
                        icon: Icon(
                          goal.isCompleted
                              ? Icons.close
                              : Icons.check_circle_outline,
                        ),
                        label: Text(
                          goal.isCompleted
                              ? 'Mark Incomplete'
                              : 'Mark Complete',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveGoal(position),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveGoal(int position) async {
    final title = _goalTitleController.text.trim();
    Navigator.pop(context);
    await ref
        .read(boardActionsProvider)
        .updateGoalTitle(widget.boardId, position, title);
  }

  @override
  Widget build(BuildContext context) {
    final boardAsync = ref.watch(boardDetailProvider(widget.boardId));
    final colorScheme = Theme.of(context).colorScheme;

    return boardAsync.when(
      loading: () => GradientMeshScaffold(
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              const Text('Failed to load board'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
      data: (board) => GradientMeshScaffold(
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(board, colorScheme),
              Expanded(
                child: _viewMode == BoardViewMode.grid
                    ? _buildGridView(board)
                    : _buildVisionBoard(board, colorScheme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Board board, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  board.title,
                  style: AppTypography.headlineMedium.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildViewToggle(colorScheme),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export coming soon')),
                  );
                },
                icon: const Icon(Icons.download_outlined),
                tooltip: 'Export',
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 48),
            child: Row(
              children: [
                Text(
                  '${board.year}',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                _dot(colorScheme),
                Text(
                  '${board.completedCount}/${board.goalCount} complete',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                _dot(colorScheme),
                Text(
                  '${board.progressPercent}%',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildViewToggle(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton(
            icon: Icons.grid_view_rounded,
            label: 'Grid',
            isSelected: _viewMode == BoardViewMode.grid,
            onTap: () => setState(() => _viewMode = BoardViewMode.grid),
            colorScheme: colorScheme,
          ),
          _toggleButton(
            icon: Icons.visibility_outlined,
            label: 'Vision',
            isSelected: _viewMode == BoardViewMode.vision,
            onTap: () => setState(() => _viewMode = BoardViewMode.vision),
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurface),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(Board board) {
    final bingoGoals = board.goals
        .map((g) => BingoGoal(title: g.title, isCompleted: g.isCompleted))
        .toList();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: BingoGrid(
            goals: bingoGoals,
            onCellTap: (index) => _showGoalDialog(board, index),
          ),
        ),
      ),
    );
  }

  Widget _buildVisionBoard(Board board, ColorScheme colorScheme) {
    final completedGoals = board.goals.where((g) => g.isCompleted).toList();

    if (completedGoals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.collections_outlined,
                size: 64,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No completed goals yet',
                style: AppTypography.headlineSmall.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete goals to see them displayed here as beautiful cards.',
                style: AppTypography.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: completedGoals.length,
      itemBuilder: (context, index) {
        final goal = completedGoals[index];
        return _buildVisionCard(goal, colorScheme);
      },
    );
  }

  Widget _buildVisionCard(Goal goal, ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.check_circle,
                  size: 48,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              goal.title ?? 'Goal',
              style: AppTypography.labelMedium.copyWith(
                color: colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
