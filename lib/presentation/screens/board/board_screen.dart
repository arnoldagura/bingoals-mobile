import 'dart:async';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../data/api/websocket_service.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/boards_provider.dart';
import '../../../data/providers/notifications_provider.dart';
import '../../../data/providers/shared_board_providers.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/gradient_mesh_background.dart';
import '../../widgets/common/styled_bottom_sheet.dart';
import '../../widgets/common/styled_text_field.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/goal/goal_grid.dart';

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
  StreamSubscription<BoardEvent>? _wsSubscription;
  bool _wsConnected = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _goalTitleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _listenToWebSocket(BoardWebSocket ws) {
    if (_wsConnected) return;
    _wsConnected = true;

    _wsSubscription = ws.events.listen((event) {
      if (!mounted) return;

      // Refresh notification badge for events that create notifications
      ref.invalidate(notificationsProvider);

      switch (event.type) {
        case 'goal_updated':
        case 'goal_completed':
          ref.invalidate(boardDetailProvider(widget.boardId));
          ref.invalidate(boardSummariesProvider);
          ref.invalidate(boardActivityProvider(widget.boardId));
          if (event.type == 'goal_completed' && event.data is Map) {
            final data = event.data as Map;
            final name = data['userName'] ?? 'Someone';
            final title = data['goalTitle'] ?? 'a goal';
            _showEventSnackBar('$name completed "$title"');
          }
          break;
        case 'member_joined':
          ref.invalidate(boardDetailProvider(widget.boardId));
          ref.invalidate(boardMembersProvider(widget.boardId));
          ref.invalidate(boardActivityProvider(widget.boardId));
          if (event.data is Map) {
            final name = (event.data as Map)['userName'] ?? 'Someone';
            _showEventSnackBar('$name joined the board');
          }
          break;
        case 'member_left':
          ref.invalidate(boardDetailProvider(widget.boardId));
          ref.invalidate(boardMembersProvider(widget.boardId));
          ref.invalidate(boardActivityProvider(widget.boardId));
          break;
        case 'board_updated':
          ref.invalidate(boardDetailProvider(widget.boardId));
          ref.invalidate(boardSummariesProvider);
          break;
        case 'comment_added':
        case 'comment_deleted':
          if (event.data is Map) {
            final goalId = (event.data as Map)['goalId'] as String?;
            if (goalId != null) {
              ref.invalidate(goalCommentsProvider(goalId));
            }
          }
          ref.invalidate(boardActivityProvider(widget.boardId));
          break;
      }
    });
  }

  void _showEventSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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

    showStyledBottomSheet(
      context: context,
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, sheetRef, _) {
          final latestBoard =
              sheetRef.watch(boardDetailProvider(widget.boardId)).valueOrNull;
          final latestGoal = latestBoard?.goals[position] ?? goal;

          return StyledBottomSheetContent(
            title: goal.isEmpty ? 'Add Goal' : 'Edit Goal',
            showClose: true,
            child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StyledTextField(
                      controller: _goalTitleController,
                      autofocus: goal.isEmpty,
                      hintText: 'Enter your goal...',
                      labelText: 'Goal Title',
                      prefixIcon: Icons.flag_outlined,
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
                    if (!goal.isEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () {
                            showDialog(
                              context: sheetContext,
                              builder: (dialogCtx) => AlertDialog(
                                title: const Text('Delete Goal?'),
                                content: const Text(
                                    'This will clear the goal, its mini-goals, and reflection. This cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogCtx),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(dialogCtx);
                                      Navigator.pop(sheetContext);
                                      try {
                                        await ref
                                            .read(boardActionsProvider)
                                            .clearGoal(widget.boardId,
                                                position);
                                      } catch (e) {
                                        _showError(e);
                                      }
                                    },
                                    child: Text('Delete',
                                        style: TextStyle(
                                            color: Colors.red.shade700)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: Icon(Icons.delete_outline,
                              size: 18, color: Colors.red.shade700),
                          label: Text('Delete Goal',
                              style:
                                  TextStyle(color: Colors.red.shade700)),
                        ),
                      ),
                    ],
                  ],
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
            StyledTextField(
              controller: titleCtrl,
              autofocus: true,
              hintText: 'Mini-goal title',
              labelText: 'Title',
              prefixIcon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 12),
            StyledTextField(
              controller: pctCtrl,
              keyboardType: TextInputType.number,
              hintText: '1-100',
              labelText: 'Weight ($remaining% remaining)',
              prefixIcon: Icons.percent,
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
            StyledTextField(
              controller: titleCtrl,
              autofocus: true,
              hintText: 'Mini-goal title',
              labelText: 'Title',
              prefixIcon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 12),
            StyledTextField(
              controller: pctCtrl,
              keyboardType: TextInputType.number,
              hintText: '1-100',
              labelText: 'Weight ($remaining% available)',
              prefixIcon: Icons.percent,
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

    showStyledBottomSheet(
      context: context,
      builder: (sheetContext) => StyledBottomSheetContent(
        title: goal.title ?? 'Goal',
        showClose: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                if (reflection?.reflectionPrompt != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(sheetContext).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Theme.of(sheetContext).colorScheme.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            color: Theme.of(sheetContext).colorScheme.secondary, size: 18),
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
                  StyledTextField(
                    controller: answerCtrl,
                    maxLines: 2,
                    labelText: 'Your Answer',
                    hintText: 'Reflect on the prompt above...',
                    prefixIcon: Icons.edit_outlined,
                  ),
                  const SizedBox(height: 16),
                ],
                StyledTextField(
                  controller: victoriesCtrl,
                  maxLines: 2,
                  labelText: 'Victories',
                  hintText: 'What went well?',
                  prefixIcon: Icons.emoji_events_outlined,
                ),
                const SizedBox(height: 12),
                StyledTextField(
                  controller: obstaclesCtrl,
                  maxLines: 2,
                  labelText: 'Obstacles',
                  hintText: 'What challenges did you face?',
                  prefixIcon: Icons.shield_outlined,
                ),
                const SizedBox(height: 12),
                StyledTextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  labelText: 'Notes',
                  hintText: 'Any other thoughts...',
                  prefixIcon: Icons.sticky_note_2_outlined,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showIconPhotoPicker(position);
                    },
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: const Text('Change Icon / Photo'),
                  ),
                ),
                const SizedBox(height: 12),
                if (board.isShared) ...[
                  _ReactionRow(
                    goalId: goal.id,
                    boardActionsProvider: boardActionsProvider,
                  ),
                  const SizedBox(height: 16),
                  _CommentsSection(goalId: goal.id),
                  const SizedBox(height: 12),
                ],
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
                      child: GradientButton(
                        label: 'Save Reflection',
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

  void _showMiniGoalChecklist(Board board, int position) {
    showStyledBottomSheet(
      context: context,
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, sheetRef, _) {
          final latestBoard =
              sheetRef.watch(boardDetailProvider(widget.boardId)).valueOrNull;
          final latestGoal = latestBoard?.goals[position] ?? board.goals[position];
          final allComplete = latestGoal.miniGoals.isNotEmpty &&
              latestGoal.miniGoals.every((mg) => mg.isComplete);

          return StyledBottomSheetContent(
            title: latestGoal.title ?? 'Goal',
            showClose: true,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
                  ...latestGoal.miniGoals.map((mg) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: mg.isComplete,
                        onChanged: (_) async {
                          try {
                            await ref.read(boardActionsProvider).toggleMiniGoal(
                                widget.boardId, position, mg.id);
                          } catch (e) {
                            _showError(e);
                          }
                        },
                        title: Text(
                          mg.title,
                          style: TextStyle(
                            decoration: mg.isComplete
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text('${mg.percentage}%',
                            style: AppTypography.caption),
                      )),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: allComplete
                        ? 'Complete Goal!'
                        : 'Complete all mini-goals first',
                    onPressed: allComplete
                        ? () {
                            Navigator.pop(sheetContext);
                            _showIconPhotoPicker(position,
                                completeFirst: true);
                          }
                        : null,
                  ),
                ],
              ),
          );
        },
      ),
    );
  }

  static const _celebrationIcons = [
    '🏆', '⭐', '🔥', '🎯', '💪', '📚', '🎨', '🏃', '💰', '🧘',
    '✈️', '🎵', '💡', '🌱', '❤️', '🎉', '🏠', '🍎', '⚡', '🌟',
    '🎓', '💼', '🏋️', '🧠', '🌍', '📝', '🔑', '🎭', '🚀', '👑',
  ];

  /// Shows the icon/photo picker bottom sheet.
  /// If [completeFirst] is true, toggles goal completion before setting
  /// the icon/photo (used when completing a goal for the first time).
  void _showIconPhotoPicker(int position, {bool completeFirst = false}) {
    var completionHandled = false;

    Future<void> handleCompletion() async {
      if (!completeFirst || completionHandled) return;
      completionHandled = true;
      try {
        final result = await ref
            .read(boardActionsProvider)
            .toggleGoalCompletion(widget.boardId, position);
        if (!mounted) return;
        _confettiController.play();
        final milestones =
            (result['milestones'] as List?)?.cast<String>() ?? [];
        if (milestones.isNotEmpty) {
          _showMilestoneCelebration(
              milestones, result['gemsAwarded'] as int? ?? 0);
        }
      } catch (e) {
        _showError(e);
      }
    }

    showStyledBottomSheet(
      context: context,
      builder: (sheetContext) => StyledBottomSheetContent(
        title: 'Add an Icon or Photo',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose an icon to represent this achievement',
                  style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(sheetContext).colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await handleCompletion();
                  },
                  child: const Text('Skip'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _celebrationIcons.length,
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await handleCompletion();
                    try {
                      await ref.read(boardActionsProvider).updateGoalIcon(
                          widget.boardId, position,
                          icon: _celebrationIcons[i]);
                    } catch (e) {
                      _showError(e);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(sheetContext).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(_celebrationIcons[i],
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(
                      ImageSource.camera,
                      sheetContext,
                      position,
                      handleCompletion,
                    ),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(
                      ImageSource.gallery,
                      sheetContext,
                      position,
                      handleCompletion,
                    ),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).then((_) => handleCompletion());
  }

  Future<void> _pickImage(
    ImageSource source,
    BuildContext sheetContext,
    int position,
    Future<void> Function() handleCompletion,
  ) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image == null) return;
    if (!mounted) return;
    Navigator.pop(sheetContext);
    await handleCompletion();
    try {
      await ref.read(boardActionsProvider).uploadGoalImage(
          widget.boardId, position, image.path);
    } catch (e) {
      _showError(e);
    }
  }

  void _showInviteSheet() async {
    // Generate invite immediately, then show the code
    try {
      final invite =
          await ref.read(boardActionsProvider).createInvite(widget.boardId);
      if (!mounted) return;

      showStyledBottomSheet(
        context: context,
        builder: (sheetContext) => StyledBottomSheetContent(
          title: 'Invite to Board',
          showClose: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share this invite code with others.',
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(sheetContext)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(sheetContext)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      invite.inviteCode,
                      style: AppTypography.headlineMedium.copyWith(
                        color: Theme.of(sheetContext).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Share this code with others',
                      style: AppTypography.caption.copyWith(
                        color: Theme.of(sheetContext)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: invite.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Invite code copied!')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Code'),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      _showError(e);
    }
  }

  void _showMembersSheet(Board board) {
    final currentUserId = ref.read(authProvider).user?.id;
    final isOwner =
        board.members.any((m) => m.id == currentUserId && m.isOwner);

    showStyledBottomSheet(
      context: context,
      builder: (sheetContext) => StyledBottomSheetContent(
        title: 'Members (${board.members.length})',
        showClose: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...board.members.map((member) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      UserAvatar(
                        imageUrl: member.avatarUrl.isNotEmpty
                            ? member.avatarUrl
                            : null,
                        initials: member.initials,
                        radius: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.displayLabel,
                              style: AppTypography.bodyLarge.copyWith(
                                color: Theme.of(sheetContext)
                                    .colorScheme
                                    .onSurface,
                              ),
                            ),
                            if (member.isOwner)
                              Text(
                                'Owner',
                                style: AppTypography.caption.copyWith(
                                  color: Theme.of(sheetContext)
                                      .colorScheme
                                      .primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isOwner &&
                          !member.isOwner &&
                          member.id != currentUserId)
                        IconButton(
                          icon: Icon(Icons.person_remove_outlined,
                              size: 20,
                              color: Theme.of(sheetContext)
                                  .colorScheme
                                  .error),
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            try {
                              await ref
                                  .read(boardActionsProvider)
                                  .removeMember(
                                      widget.boardId, member.id);
                            } catch (e) {
                              _showError(e);
                            }
                          },
                        ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _showActivityFeed();
                },
                icon: const Icon(Icons.history_outlined, size: 18),
                label: const Text('Activity'),
              ),
            ),
            const SizedBox(height: 8),
            if (isOwner)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _showInviteSheet();
                  },
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Invite Members'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Theme.of(sheetContext).colorScheme.error,
                    side: BorderSide(
                        color: Theme.of(sheetContext).colorScheme.error),
                  ),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    try {
                      await ref
                          .read(boardActionsProvider)
                          .leaveBoard(widget.boardId);
                      if (mounted) context.go('/');
                    } catch (e) {
                      _showError(e);
                    }
                  },
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Leave Board'),
                ),
              ),
          ],
        ),
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
      data: (board) {
        // Watch the WebSocket provider to keep it alive for shared boards
        if (board.isShared) {
          final ws = ref.watch(boardWebSocketProvider(widget.boardId));
          _listenToWebSocket(ws);
        }
        return GradientMeshScaffold(
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
      );
      },
    );
  }

  Widget _buildHeader(Board board, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Back + type chip + actions
          Row(
            children: [
              IconButton(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.arrow_back),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: board.isShared
                      ? Colors.green.withValues(alpha: 0.15)
                      : colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  board.isShared ? 'Shared' : 'Personal',
                  style: AppTypography.caption.copyWith(
                    color: board.isShared ? Colors.green : colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (board.isShared) ...[
                IconButton(
                  onPressed: _showInviteSheet,
                  icon: const Icon(Icons.person_add_outlined, size: 22),
                  tooltip: 'Invite',
                ),
                IconButton(
                  onPressed: () => _showMembersSheet(board),
                  icon: const Icon(Icons.group_outlined),
                  tooltip: 'Members',
                ),
              ],
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
          // Title: full width, wraps freely
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 0, 4),
            child: Text(
              board.title,
              style: AppTypography.headlineMedium.copyWith(
                color: colorScheme.onSurface,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Stats + View toggle
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        '${board.year}',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      _dot(colorScheme),
                      Flexible(
                        child: Text(
                          '${board.completedCount}/${board.goalCount} complete',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
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
                      if (board.isShared && board.members.isNotEmpty) ...[
                        _dot(colorScheme),
                        _buildMemberAvatars(board.members, colorScheme),
                      ],
                    ],
                  ),
                ),
                _buildViewToggle(colorScheme),
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

  Widget _buildMemberAvatars(List<MemberInfo> members, ColorScheme colorScheme) {
    const maxShow = 3;
    final show = members.take(maxShow).toList();
    final extra = members.length - maxShow;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: show.length * 18.0 + 6,
          height: 22,
          child: Stack(
            children: [
              for (var i = 0; i < show.length; i++)
                Positioned(
                  left: i * 14.0,
                  child: UserAvatar(
                    imageUrl: show[i].avatarUrl.isNotEmpty
                        ? show[i].avatarUrl
                        : null,
                    initials: show[i].initials,
                    radius: 11,
                  ),
                ),
            ],
          ),
        ),
        if (extra > 0)
          Text(
            '+$extra',
            style: AppTypography.caption.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
      ],
    );
  }

  void _showActivityFeed() {
    showStyledBottomSheet(
      context: context,
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, sheetRef, _) {
          final activity =
              sheetRef.watch(boardActivityProvider(widget.boardId));
          return StyledBottomSheetContent(
            title: 'Activity',
            showClose: true,
            child: activity.when(
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox(
                height: 100,
                child: Center(child: Text('Failed to load activity')),
              ),
              data: (page) {
                if (page.activities.isEmpty) {
                  return SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'No activity yet',
                        style: AppTypography.bodySmall.copyWith(
                          color: Theme.of(sheetContext)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: page.activities.map((a) {
                    final userName = a.user?.displayLabel ?? 'Someone';
                    final icon = _activityIcon(a.actionType);
                    final desc = _activityDescription(a.actionType, userName);
                    final ago = _timeAgo(a.createdAt);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, size: 18,
                              color: Theme.of(sheetContext)
                                  .colorScheme
                                  .primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(desc,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Theme.of(sheetContext)
                                          .colorScheme
                                          .onSurface,
                                    )),
                                Text(ago,
                                    style: AppTypography.caption.copyWith(
                                      color: Theme.of(sheetContext)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.4),
                                      fontSize: 11,
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _activityIcon(String actionType) {
    switch (actionType) {
      case 'goal_completed':
        return Icons.check_circle_outline;
      case 'member_joined':
        return Icons.person_add_outlined;
      case 'member_left':
        return Icons.person_remove_outlined;
      case 'reaction':
        return Icons.favorite_outline;
      default:
        return Icons.info_outline;
    }
  }

  String _activityDescription(String actionType, String userName) {
    switch (actionType) {
      case 'goal_completed':
        return '$userName completed a goal';
      case 'member_joined':
        return '$userName joined the board';
      case 'member_left':
        return '$userName left the board';
      case 'reaction':
        return '$userName reacted to a goal';
      default:
        return '$userName performed an action';
    }
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
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
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: GoalGrid(
            goals: board.goals,
            gridSize: board.gridSize,
            onCellTap: (index) {
              final goal = board.goals[index];
              if (goal.isCompleted) {
                _showReflectionSheet(board, index);
              } else {
                _showGoalDialog(board, index);
              }
            },
            onCellLongPress: (index) async {
              final goal = board.goals[index];
              if (goal.isEmpty) return;

              // Has mini-goals and not yet completed → show checklist
              if (goal.miniGoals.isNotEmpty && !goal.isCompleted) {
                _showMiniGoalChecklist(board, index);
                return;
              }

              // Not completed → show picker first, then complete
              if (!goal.isCompleted) {
                _showIconPhotoPicker(index, completeFirst: true);
                return;
              }

              // Already completed → uncomplete directly
              try {
                await ref
                    .read(boardActionsProvider)
                    .toggleGoalCompletion(widget.boardId, index);
              } catch (e) {
                _showError(e);
              }
            },
          ),
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
    final hasPhoto = goal.imageUrl != null && goal.imageUrl!.isNotEmpty;
    final hasIcon = goal.icon != null && goal.icon!.isNotEmpty;

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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: hasPhoto
                ? _buildVisionCardPhoto(goal)
                : Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: hasIcon
                          ? Text(goal.icon!,
                              style: const TextStyle(fontSize: 48))
                          : Icon(Icons.check_circle,
                              size: 48, color: colorScheme.primary),
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

  Widget _buildVisionCardPhoto(Goal goal) {
    final fullUrl = goal.imageUrl!.startsWith('http')
        ? goal.imageUrl!
        : '${ApiConstants.baseUrl}${goal.imageUrl}';
    return CachedNetworkImage(
      imageUrl: fullUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, __) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image_outlined, size: 32),
      ),
    );
  }
}

class _ReactionRow extends ConsumerStatefulWidget {
  final String goalId;
  final ProviderListenable<BoardActions> boardActionsProvider;

  const _ReactionRow({
    required this.goalId,
    required this.boardActionsProvider,
  });

  @override
  ConsumerState<_ReactionRow> createState() => _ReactionRowState();
}

class _ReactionRowState extends ConsumerState<_ReactionRow> {
  static const _reactions = [
    ('fire', '🔥'),
    ('heart', '❤️'),
    ('clap', '👏'),
    ('star', '⭐'),
  ];

  String? _selectedType;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _reactions.map((r) {
        final isSelected = _selectedType == r.$1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () async {
              try {
                final result = await ref
                    .read(widget.boardActionsProvider)
                    .addReaction(widget.goalId, r.$1);
                if (mounted) {
                  final action = result['action'] as String?;
                  setState(() {
                    _selectedType = action == 'added' ? r.$1 : null;
                  });
                }
              } catch (_) {}
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.3)
                      : Colors.transparent,
                ),
              ),
              child: Text(r.$2, style: const TextStyle(fontSize: 20)),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CommentsSection extends ConsumerStatefulWidget {
  final String goalId;

  const _CommentsSection({required this.goalId});

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(boardActionsProvider).addComment(widget.goalId, text);
      _controller.clear();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add comment')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(goalCommentsProvider(widget.goalId));
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = ref.watch(authProvider).user?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              'Comments',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            commentsAsync.when(
              data: (comments) => comments.isEmpty
                  ? const SizedBox.shrink()
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${comments.length}',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Input row
        Row(
          children: [
            Expanded(
              child: StyledTextField(
                controller: _controller,
                maxLines: 1,
                hintText: 'Add a comment...',
                prefixIcon: Icons.comment_outlined,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.send, color: colorScheme.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Comments list
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No comments yet. Be the first!',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }
            return Column(
              children: comments.map((comment) {
                final isOwn = comment.userId == currentUserId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(
                        initials: comment.user?.initials ?? '?',
                        imageUrl: comment.user?.avatarUrl,
                        radius: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    comment.user?.displayLabel ?? 'Unknown',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _formatTime(comment.createdAt),
                                    style: AppTypography.bodySmall.copyWith(
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.text,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (isOwn)
                        IconButton(
                          icon: Icon(Icons.delete_outline,
                              size: 16,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.4)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(boardActionsProvider)
                                  .deleteComment(
                                      widget.goalId, comment.id);
                            } catch (_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Failed to delete comment')),
                                );
                              }
                            }
                          },
                        ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, __) => Text(
            'Failed to load comments',
            style: AppTypography.bodySmall
                .copyWith(color: colorScheme.error),
          ),
        ),
      ],
    );
  }
}
