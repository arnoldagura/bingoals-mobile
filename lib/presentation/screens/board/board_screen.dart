import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/boards_provider.dart';
import '../../widgets/goal/goal_grid.dart';
import '../../widgets/common/gradient_mesh_background.dart';

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
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _goalTitleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    if (!mounted) return;
    String message = 'Something went wrong';
    if (error is DioException && error.response?.data is Map) {
      message = (error.response!.data as Map)['error'] ?? message;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  void _showGoalDialog(Board board, int position) {
    final goal = board.goals[position];
    _goalTitleController.text = goal.title ?? '';
    final miniGoalTitleController = TextEditingController();
    final miniGoalPctController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, sheetRef, _) {
          final latestBoard =
              sheetRef.watch(boardDetailProvider(widget.boardId)).valueOrNull;
          final latestGoal = latestBoard?.goals[position] ?? goal;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
              ),
              child: SingleChildScrollView(
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
                      autofocus: goal.isEmpty,
                      decoration: const InputDecoration(
                        hintText: 'Enter your goal...',
                        labelText: 'Goal Title',
                      ),
                      onSubmitted: (_) => _saveGoal(position),
                    ),
                    if (!latestGoal.isEmpty) ...[
                      const SizedBox(height: 20),
                      if (latestGoal.miniGoals.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: latestGoal.progress / 100,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${latestGoal.progress}%',
                                style: AppTypography.labelSmall),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mini-Goals',
                              style: AppTypography.labelMedium
                                  .copyWith(fontWeight: FontWeight.w600)),
                          TextButton.icon(
                            onPressed: () => _showAddMiniGoalDialog(
                              sheetContext,
                              position,
                              latestGoal,
                              miniGoalTitleController,
                              miniGoalPctController,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                      if (latestGoal.miniGoals.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Break this goal into smaller tasks',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ...latestGoal.miniGoals.map((mg) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Checkbox(
                              value: mg.isComplete,
                              onChanged: (_) async {
                                try {
                                  await ref.read(boardActionsProvider).toggleMiniGoal(
                                      widget.boardId, position, mg.id);
                                } catch (e) {
                                  _showError(e);
                                }
                              },
                            ),
                            title: Text(
                              mg.title,
                              style: TextStyle(
                                decoration: mg.isComplete
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            onTap: () => _showEditMiniGoalDialog(
                              sheetContext,
                              position,
                              latestGoal,
                              mg,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${mg.percentage}%',
                                    style: AppTypography.caption),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(boardActionsProvider)
                                          .deleteMiniGoal(widget.boardId,
                                              position, mg.id);
                                    } catch (e) {
                                      _showError(e);
                                    }
                                  },
                                ),
                              ],
                            ),
                          )),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (!goal.isEmpty &&
                            latestGoal.miniGoals.isEmpty) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                Navigator.pop(context);
                                try {
                                  await ref
                                      .read(boardActionsProvider)
                                      .toggleGoalCompletion(
                                          widget.boardId, position);
                                } catch (e) {
                                  _showError(e);
                                }
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
        },
      ),
    );
  }

  void _showAddMiniGoalDialog(
    BuildContext sheetContext,
    int position,
    Goal goal,
    TextEditingController titleCtrl,
    TextEditingController pctCtrl,
  ) {
    titleCtrl.clear();
    final usedPct =
        goal.miniGoals.fold<int>(0, (sum, mg) => sum + mg.percentage);
    final remaining = 100 - usedPct;
    pctCtrl.text = remaining > 0 ? '$remaining' : '';

    showDialog(
      context: sheetContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Mini-Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Mini-goal title',
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pctCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '1-100',
                labelText: 'Weight (%)',
                helperText: '$remaining% remaining',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final pct = int.tryParse(pctCtrl.text.trim()) ?? 0;
              if (title.isEmpty || pct < 1) return;
              Navigator.pop(ctx);
              try {
                await ref.read(boardActionsProvider).createMiniGoal(
                      widget.boardId,
                      position,
                      title: title,
                      percentage: pct,
                    );
              } catch (e) {
                _showError(e);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditMiniGoalDialog(
    BuildContext sheetContext,
    int position,
    Goal goal,
    MiniGoal miniGoal,
  ) {
    final titleCtrl = TextEditingController(text: miniGoal.title);
    final pctCtrl = TextEditingController(text: '${miniGoal.percentage}');
    final otherPct = goal.miniGoals
        .where((mg) => mg.id != miniGoal.id)
        .fold<int>(0, (sum, mg) => sum + mg.percentage);
    final remaining = 100 - otherPct;

    showDialog(
      context: sheetContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Mini-Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Mini-goal title',
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pctCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '1-100',
                labelText: 'Weight (%)',
                helperText: '$remaining% available',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final pct = int.tryParse(pctCtrl.text.trim()) ?? 0;
              if (title.isEmpty || pct < 1) return;
              Navigator.pop(ctx);
              try {
                await ref.read(boardActionsProvider).updateMiniGoal(
                      widget.boardId,
                      position,
                      miniGoal.id,
                      title: title,
                      percentage: pct,
                    );
              } catch (e) {
                _showError(e);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReflectionSheet(Board board, int position) {
    final goal = board.goals[position];
    final reflection = goal.reflection;
    final answerCtrl = TextEditingController(text: reflection?.reflectionAnswer);
    final obstaclesCtrl = TextEditingController(text: reflection?.obstacles);
    final victoriesCtrl = TextEditingController(text: reflection?.victories);
    final notesCtrl = TextEditingController(text: reflection?.notes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.success, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        goal.title ?? 'Goal',
                        style: AppTypography.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (reflection?.reflectionPrompt != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: Color(0xFFF59E0B), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reflection!.reflectionPrompt!,
                            style: AppTypography.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: answerCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Your Answer',
                      hintText: 'Reflect on the prompt above...',
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: victoriesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Victories',
                    hintText: 'What went well?',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: obstaclesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Obstacles',
                    hintText: 'What challenges did you face?',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Any other thoughts...',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _showGoalDialog(board, position);
                        },
                        child: const Text('Edit Goal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          try {
                            await ref.read(boardActionsProvider).upsertReflection(
                                  widget.boardId,
                                  position,
                                  reflectionAnswer:
                                      answerCtrl.text.trim().isEmpty
                                          ? null
                                          : answerCtrl.text.trim(),
                                  victories: victoriesCtrl.text.trim().isEmpty
                                      ? null
                                      : victoriesCtrl.text.trim(),
                                  obstacles: obstaclesCtrl.text.trim().isEmpty
                                      ? null
                                      : obstaclesCtrl.text.trim(),
                                  notes: notesCtrl.text.trim().isEmpty
                                      ? null
                                      : notesCtrl.text.trim(),
                                );
                          } catch (e) {
                            _showError(e);
                          }
                        },
                        child: const Text('Save Reflection'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMilestoneCelebration(List<String> milestones, int gemsAwarded) {
    final labels = milestones.map((m) {
      switch (m) {
        case 'row':
          return 'Row Complete';
        case 'column':
          return 'Column Complete';
        case 'diagonal':
          return 'Diagonal Complete';
        case 'anti-diagonal':
          return 'Anti-Diagonal Complete';
        case 'corners':
          return 'Four Corners';
        case 'blackout':
          return 'Board Blackout!';
        default:
          return m;
      }
    }).join(' + ');

    _confettiController.play();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text('$labels  +$gemsAwarded gems'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveGoal(int position) async {
    final title = _goalTitleController.text.trim();
    Navigator.pop(context);
    try {
      await ref
          .read(boardActionsProvider)
          .updateGoalTitle(widget.boardId, position, title);
    } catch (e) {
      _showError(e);
    }
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
        body: Stack(
          children: [
            SafeArea(
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
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                maxBlastForce: 20,
                minBlastForce: 5,
                gravity: 0.2,
                colors: AppColors.confettiColors,
              ),
            ),
          ],
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: GoalGrid(
            goals: board.goals,
            gridSize: board.gridSize,
            onCellTap: (index) {
              final goal = board.goals[index];
              if (goal.isCompleted && !goal.isGraceSquare) {
                _showReflectionSheet(board, index);
              } else {
                _showGoalDialog(board, index);
              }
            },
            onCellLongPress: (index) async {
              final goal = board.goals[index];
              if (!goal.isEmpty) {
                try {
                  final result = await ref
                      .read(boardActionsProvider)
                      .toggleGoalCompletion(widget.boardId, index);

                  if (!mounted) return;

                  if (goal.isInProgress) {
                    _confettiController.play();
                  }

                  final milestones = (result['milestones'] as List?)
                          ?.cast<String>() ??
                      [];
                  if (milestones.isNotEmpty) {
                    _showMilestoneCelebration(milestones,
                        result['gemsAwarded'] as int? ?? 0);
                  }
                } catch (e) {
                  _showError(e);
                }
              }
            },
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
