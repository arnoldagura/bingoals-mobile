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
import '../../../core/constants/board_categories.dart';
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
  final _notesController = TextEditingController();
  final _victoriesController = TextEditingController();
  final _obstaclesController = TextEditingController();
  late final ConfettiController _confettiController;
  StreamSubscription<BoardEvent>? _wsSubscription;
  bool _wsConnected = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    _goalTitleController.dispose();
    _notesController.dispose();
    _victoriesController.dispose();
    _obstaclesController.dispose();
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
    _notesController.text = goal.reflection?.notes ?? '';
    _victoriesController.text = goal.reflection?.victories ?? '';
    _obstaclesController.text = goal.reflection?.obstacles ?? '';
    final miniGoalTitleController = TextEditingController();
    final miniGoalPctController = TextEditingController();
    final cat = BoardCategory.fromKey(board.category);
    final togglingMgId = ValueNotifier<String?>(null);

    showStyledBottomSheet(
      context: context,
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, sheetRef, _) {
          final latestBoard = sheetRef
              .watch(boardDetailProvider(widget.boardId))
              .valueOrNull;
          final latestGoal = latestBoard?.goals[position] ?? goal;
          final colorScheme = Theme.of(sheetContext).colorScheme;

          // Small caps section label helper
          Widget sectionLabel(String text) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              text,
              style: AppTypography.labelSmall.copyWith(
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    8,
                    24,
                    MediaQuery.of(sheetContext).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Category chip + close button ──
                      Row(
                        children: [
                          if (cat != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
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
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.06,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                board.title,
                                style: AppTypography.caption.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          GestureDetector(
                            onTap: () => Navigator.pop(sheetContext),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.06,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Goal title ──
                      StyledTextField(
                        controller: _goalTitleController,
                        autofocus: goal.isEmpty,
                        labelText: 'Goal Title',
                        hintText: goal.isEmpty
                            ? 'e.g., Run a 5K by July'
                            : 'Rename goal...',
                        onSubmitted: (_) => _saveGoal(position),
                      ),
                      const SizedBox(height: 24),

                      // ── Milestones (only for existing goals) ──
                      if (!latestGoal.isEmpty) ...[
                        // ── Mood color picker ──
                        sectionLabel('MOOD'),
                        _MoodPicker(
                          currentMood: latestGoal.mood,
                          onMoodSelected: (mood) async {
                            try {
                              await ref
                                  .read(boardActionsProvider)
                                  .updateGoalMood(
                                    widget.boardId,
                                    position,
                                    mood,
                                  );
                            } catch (e) {
                              _showError(e);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        sectionLabel('MILESTONES'),
                        if (latestGoal.miniGoals.isNotEmpty) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: latestGoal.progress / 100,
                                    minHeight: 8,
                                    backgroundColor: colorScheme.onSurface
                                        .withValues(alpha: 0.08),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _moodColor(latestGoal.mood, colorScheme),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${latestGoal.progress}%',
                                style: AppTypography.labelSmall.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.55,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                        // Milestone rows with circle checkboxes
                        ...() {
                          final effs = _effectivePercentages(
                            latestGoal.miniGoals,
                          );
                          return latestGoal.miniGoals
                              .asMap()
                              .entries
                              .map(
                                (e) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    10,
                                    8,
                                    10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: e.value.isComplete
                                        ? colorScheme.primary.withValues(
                                            alpha: 0.04,
                                          )
                                        : colorScheme.onSurface.withValues(
                                            alpha: 0.03,
                                          ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: e.value.isComplete
                                          ? colorScheme.primary.withValues(
                                              alpha: 0.12,
                                            )
                                          : colorScheme.onSurface.withValues(
                                              alpha: 0.08,
                                            ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Animated circle toggle with loading
                                      ValueListenableBuilder<String?>(
                                        valueListenable: togglingMgId,
                                        builder: (_, toggling, _) {
                                          final isLoading =
                                              toggling == e.value.id;
                                          return GestureDetector(
                                            onTap: isLoading
                                                ? null
                                                : () async {
                                                    togglingMgId.value =
                                                        e.value.id;
                                                    try {
                                                      await ref
                                                          .read(
                                                            boardActionsProvider,
                                                          )
                                                          .toggleMiniGoal(
                                                            widget.boardId,
                                                            position,
                                                            e.value.id,
                                                          );
                                                    } catch (err) {
                                                      _showError(err);
                                                    } finally {
                                                      togglingMgId.value = null;
                                                    }
                                                  },
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: isLoading
                                                  ? CircularProgressIndicator(
                                                      strokeWidth: 1.5,
                                                      color:
                                                          colorScheme.primary,
                                                    )
                                                  : AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 200,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color:
                                                              e.value.isComplete
                                                              ? colorScheme
                                                                    .primary
                                                              : colorScheme
                                                                    .onSurface
                                                                    .withValues(
                                                                      alpha:
                                                                          0.25,
                                                                    ),
                                                          width: 1.5,
                                                        ),
                                                        color:
                                                            e.value.isComplete
                                                            ? colorScheme
                                                                  .primary
                                                            : Colors
                                                                  .transparent,
                                                      ),
                                                      child: e.value.isComplete
                                                          ? Icon(
                                                              Icons.check,
                                                              size: 13,
                                                              color: colorScheme
                                                                  .onPrimary,
                                                            )
                                                          : null,
                                                    ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => _showEditMiniGoalDialog(
                                            sheetContext,
                                            position,
                                            latestGoal,
                                            e.value,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.value.title,
                                                style: AppTypography.bodyMedium
                                                    .copyWith(
                                                      color: e.value.isComplete
                                                          ? colorScheme
                                                                .onSurface
                                                                .withValues(
                                                                  alpha: 0.4,
                                                                )
                                                          : colorScheme
                                                                .onSurface,
                                                      decoration:
                                                          e.value.isComplete
                                                          ? TextDecoration
                                                                .lineThrough
                                                          : null,
                                                      decorationColor:
                                                          colorScheme.onSurface
                                                              .withValues(
                                                                alpha: 0.4,
                                                              ),
                                                    ),
                                              ),
                                              Text(
                                                _formatPct(effs[e.key]),
                                                style: AppTypography.caption
                                                    .copyWith(
                                                      color: colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.35,
                                                          ),
                                                      fontSize: 10,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      // Camera icon for memory upload
                                      GestureDetector(
                                        onTap: () => _pickImageForMilestone(
                                          sheetContext,
                                          position,
                                          e.value.id,
                                        ),
                                        child: e.value.imageUrl != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Image.network(
                                                  e.value.imageUrl!.startsWith(
                                                        'http',
                                                      )
                                                      ? e.value.imageUrl!
                                                      : '${ApiConstants.baseUrl}${e.value.imageUrl}',
                                                  width: 22,
                                                  height: 22,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => Icon(
                                                    Icons.add_a_photo_outlined,
                                                    size: 16,
                                                    color: colorScheme.onSurface
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                              )
                                            : Icon(
                                                Icons.add_a_photo_outlined,
                                                size: 16,
                                                color: colorScheme.onSurface
                                                    .withValues(alpha: 0.3),
                                              ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () async {
                                          try {
                                            await ref
                                                .read(boardActionsProvider)
                                                .deleteMiniGoal(
                                                  widget.boardId,
                                                  position,
                                                  e.value.id,
                                                );
                                          } catch (err) {
                                            _showError(err);
                                          }
                                        },
                                        child: Icon(
                                          Icons.close,
                                          size: 16,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList();
                        }(),
                        // + Add Milestone
                        GestureDetector(
                          onTap: () => _showAddMiniGoalDialog(
                            sheetContext,
                            position,
                            latestGoal,
                            miniGoalTitleController,
                            miniGoalPctController,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.15,
                                ),
                              ),
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.02,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 16,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Add Milestone',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Journal Notes ──
                        sectionLabel('JOURNAL NOTES'),
                        StyledTextField(
                          controller: _notesController,
                          maxLines: 3,
                          hintText: 'How is this goal going?',
                        ),
                        const SizedBox(height: 24),

                        // ── Reflection (completed goals only) ──
                        if (latestGoal.isCompleted) ...[
                          sectionLabel('REFLECTION'),
                          _buildReflectionField(
                            context: sheetContext,
                            controller: _victoriesController,
                            hintText: 'What went well?',
                            prefixIcon: Icons.emoji_events_outlined,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 12),
                          _buildReflectionField(
                            context: sheetContext,
                            controller: _obstaclesController,
                            hintText: 'What challenges did you face?',
                            prefixIcon: Icons.shield_outlined,
                            colorScheme: colorScheme,
                          ),
                          const SizedBox(height: 24),
                        ],

                        // ── Memories ──
                        sectionLabel('MEMORIES'),
                        SizedBox(
                          height: 110,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ...latestGoal.memories.map((memory) {
                                final fullUrl =
                                    memory.imageUrl.startsWith('http')
                                    ? memory.imageUrl
                                    : '${ApiConstants.baseUrl}${memory.imageUrl}';
                                return GestureDetector(
                                  onLongPress: () => _showMemoryOptions(
                                    sheetContext,
                                    position,
                                    memory,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: CachedNetworkImage(
                                                imageUrl: fullUrl,
                                                width: 90,
                                                height: 90,
                                                fit: BoxFit.cover,
                                                placeholder: (_, _) => Container(
                                                  width: 90,
                                                  height: 90,
                                                  color: colorScheme
                                                      .surfaceContainerHighest,
                                                ),
                                                errorWidget: (_, _, _) => Container(
                                                  width: 90,
                                                  height: 90,
                                                  color: colorScheme
                                                      .surfaceContainerHighest,
                                                  child: const Icon(
                                                    Icons.broken_image_outlined,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (memory.isBoardImage)
                                              Positioned(
                                                top: 4,
                                                left: 4,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
                                                        color: Colors.amber,
                                                        shape: BoxShape.circle,
                                                      ),
                                                  child: const Icon(
                                                    Icons.star_rounded,
                                                    size: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (memory.label.isNotEmpty)
                                          SizedBox(
                                            width: 90,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                memory.label,
                                                style: AppTypography.caption
                                                    .copyWith(
                                                      fontSize: 10,
                                                      color: colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                              // Add memory button
                              GestureDetector(
                                onTap: () =>
                                    _pickImageForGoal(sheetContext, position),
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1.5,
                                    ),
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.03,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 22,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add memory',
                                        style: AppTypography.caption.copyWith(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.35),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // ── Stamp Complete / Mark Incomplete ──
                      if (!goal.isEmpty && latestGoal.miniGoals.isEmpty) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: goal.isCompleted
                                  ? colorScheme.onSurface.withValues(
                                      alpha: 0.08,
                                    )
                                  : colorScheme.onSurface,
                              foregroundColor: goal.isCompleted
                                  ? colorScheme.onSurface
                                  : colorScheme.surface,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                                side: goal.isCompleted
                                    ? BorderSide(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.15,
                                        ),
                                      )
                                    : BorderSide.none,
                              ),
                            ),
                            icon: Icon(
                              goal.isCompleted
                                  ? Icons.undo
                                  : Icons.verified_outlined,
                              size: 18,
                            ),
                            label: Text(
                              goal.isCompleted
                                  ? 'Mark Incomplete'
                                  : 'Stamp Complete',
                              style: AppTypography.button.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              if (goal.isCompleted) {
                                // Uncomplete directly
                                ref
                                    .read(boardActionsProvider)
                                    .toggleGoalCompletion(
                                      widget.boardId,
                                      position,
                                    )
                                    .catchError((e) {
                                      _showError(e);
                                      return <String, dynamic>{};
                                    });
                              } else {
                                // Show icon/photo picker, which completes
                                // the goal after the user picks or skips
                                _showIconPhotoPicker(
                                  position,
                                  completeFirst: true,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Save ──
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.2,
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _saveGoal(position),
                          child: Text(
                            goal.isEmpty ? 'Create Goal' : 'Save',
                            style: AppTypography.button.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),

                      // ── Delete Goal ──
                      if (!goal.isEmpty) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: sheetContext,
                                builder: (dialogCtx) => AlertDialog(
                                  title: const Text('Delete Goal?'),
                                  content: const Text(
                                    'This will clear the goal, its milestones, and notes. This cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogCtx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(dialogCtx);
                                        Navigator.pop(sheetContext);
                                        try {
                                          await ref
                                              .read(boardActionsProvider)
                                              .clearGoal(
                                                widget.boardId,
                                                position,
                                              );
                                        } catch (e) {
                                          _showError(e);
                                        }
                                      },
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 14,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Delete Goal',
                                  style: AppTypography.caption.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _pickImageForGoal(BuildContext sheetContext, int position) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: sheetContext,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image == null) return;
    if (!mounted) return;
    // Prompt for optional label
    final labelController = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a caption'),
        content: TextField(
          controller: labelController,
          decoration: const InputDecoration(hintText: 'Add a caption...'),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (_) => Navigator.pop(ctx, labelController.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, ''),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, labelController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    try {
      await ref
          .read(boardActionsProvider)
          .addGoalMemory(
            widget.boardId,
            position,
            image.path,
            label: label ?? '',
          );
    } catch (e) {
      _showError(e);
    }
  }

  void _showMemoryOptions(
    BuildContext sheetContext,
    int position,
    dynamic memory,
  ) {
    showModalBottomSheet(
      context: sheetContext,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!memory.isBoardImage)
              ListTile(
                leading: const Icon(Icons.star_outline_rounded),
                title: const Text('Set as board image'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  try {
                    await ref
                        .read(boardActionsProvider)
                        .setGoalBoardImage(widget.boardId, position, memory.id);
                  } catch (e) {
                    _showError(e);
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit label'),
              onTap: () async {
                Navigator.pop(sheetContext);
                if (!mounted) return;
                final controller = TextEditingController(text: memory.label);
                final newLabel = await showDialog<String>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Edit caption'),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: 'Add a caption...',
                      ),
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) =>
                          Navigator.pop(ctx, controller.text.trim()),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, null),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(ctx, controller.text.trim()),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );
                if (newLabel == null || !mounted) return;
                try {
                  await ref
                      .read(boardActionsProvider)
                      .updateGoalMemoryLabel(
                        widget.boardId,
                        position,
                        memory.id,
                        newLabel,
                      );
                } catch (e) {
                  _showError(e);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(sheetContext);
                try {
                  await ref
                      .read(boardActionsProvider)
                      .deleteGoalMemory(widget.boardId, position, memory.id);
                } catch (e) {
                  _showError(e);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _pickImageForMilestone(
    BuildContext sheetContext,
    int position,
    String miniGoalId,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: sheetContext,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image == null) return;
    try {
      final actions = ref.read(boardActionsProvider);
      final url = await actions.uploadImage(image.path);
      await actions.updateMilestoneImage(
        widget.boardId,
        position,
        miniGoalId,
        url,
      );
    } catch (e) {
      _showError(e);
    }
  }

  /// Formats a percentage double cleanly: integer if whole, 1 decimal otherwise.
  static String _formatPct(double pct) {
    return pct == pct.roundToDouble()
        ? '${pct.round()}%'
        : '${pct.toStringAsFixed(1)}%';
  }

  /// Computes effective display percentages for a list of mini-goals.
  /// Goals without a set percentage share the remaining % equally.
  static List<double> _effectivePercentages(List<MiniGoal> miniGoals) {
    if (miniGoals.isEmpty) return [];
    final setPct = miniGoals
        .where((mg) => mg.percentage != null)
        .fold<double>(0, (s, mg) => s + mg.percentage!);
    final unsetCount = miniGoals.where((mg) => mg.percentage == null).length;
    final eachUnset = unsetCount > 0 ? (100.0 - setPct) / unsetCount : 0.0;
    return miniGoals
        .map(
          (mg) => mg.percentage != null ? mg.percentage!.toDouble() : eachUnset,
        )
        .toList();
  }

  void _showAddMiniGoalDialog(
    BuildContext sheetContext,
    int position,
    Goal goal,
    TextEditingController titleCtrl,
    TextEditingController pctCtrl,
  ) {
    titleCtrl.clear();
    pctCtrl.clear();

    // Remaining weight budget for new milestone
    final usedPct = goal.miniGoals
        .where((mg) => mg.percentage != null)
        .fold<int>(0, (s, mg) => s + mg.percentage!);
    final maxAllowed = (100 - usedPct).clamp(0, 100);

    showStyledBottomSheet(
      context: context,
      builder: (ctx) => StyledBottomSheetContent(
        title: 'Add Milestone',
        showClose: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StyledTextField(
              controller: titleCtrl,
              autofocus: true,
              hintText: 'What is this milestone?',
              labelText: 'Title',
              prefixIcon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 12),
            StyledTextField(
              controller: pctCtrl,
              keyboardType: TextInputType.number,
              hintText: 'Auto (leave blank to auto-split)',
              labelText: 'Weight %',
              prefixIcon: Icons.percent,
            ),
            if (usedPct > 0) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '$maxAllowed% of 100% remaining',
                  style: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 11,
                    color: Color(0xFF888888),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  final pctText = pctCtrl.text.trim();
                  final pct = pctText.isEmpty ? null : int.tryParse(pctText);
                  // Validate weight
                  if (pct != null) {
                    if (pct < 1 || pct > 100) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Weight must be between 1 and 100'),
                        ),
                      );
                      return;
                    }
                    if (pct > maxAllowed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Only $maxAllowed% remaining across milestones',
                          ),
                        ),
                      );
                      return;
                    }
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref
                        .read(boardActionsProvider)
                        .createMiniGoal(
                          widget.boardId,
                          position,
                          title: title,
                          percentage: pct,
                        );
                  } catch (e) {
                    _showError(e);
                  }
                },
                child: const Text('Add Milestone'),
              ),
            ),
          ],
        ),
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
    final pctCtrl = TextEditingController(
      text: miniGoal.percentage != null ? '${miniGoal.percentage}' : '',
    );

    // Remaining budget excluding this milestone's own weight
    final usedPct = goal.miniGoals
        .where((mg) => mg.percentage != null && mg.id != miniGoal.id)
        .fold<int>(0, (s, mg) => s + mg.percentage!);
    final maxAllowed = (100 - usedPct).clamp(0, 100);

    showStyledBottomSheet(
      context: context,
      builder: (ctx) => StyledBottomSheetContent(
        title: 'Edit Milestone',
        showClose: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StyledTextField(
              controller: titleCtrl,
              autofocus: true,
              hintText: 'What is this milestone?',
              labelText: 'Title',
              prefixIcon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 12),
            StyledTextField(
              controller: pctCtrl,
              keyboardType: TextInputType.number,
              hintText: 'Auto (leave blank to auto-split)',
              labelText: 'Weight %',
              prefixIcon: Icons.percent,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                'Max $maxAllowed% — unset milestones split remaining evenly',
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 11,
                  color: Color(0xFF888888),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  final pctText = pctCtrl.text.trim();
                  final pct = pctText.isEmpty ? null : int.tryParse(pctText);
                  if (pct != null) {
                    if (pct < 1 || pct > 100) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Weight must be between 1 and 100'),
                        ),
                      );
                      return;
                    }
                    if (pct > maxAllowed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Only $maxAllowed% remaining across milestones',
                          ),
                        ),
                      );
                      return;
                    }
                  }
                  Navigator.pop(ctx);
                  try {
                    await ref
                        .read(boardActionsProvider)
                        .updateMiniGoal(
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
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMilestoneCelebration(List<String> milestones, int gemsAwarded) {
    final labels = milestones
        .map((m) {
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
        })
        .join(' + ');

    _confettiController.play();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(child: Text('$labels  +$gemsAwarded gems')),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showMiniGoalChecklist(Board board, int position) {
    final togglingMgId = ValueNotifier<String?>(null);

    showStyledBottomSheet(
      context: context,
      builder: (sheetContext) => Consumer(
        builder: (sheetContext, sheetRef, _) {
          final latestBoard = sheetRef
              .watch(boardDetailProvider(widget.boardId))
              .valueOrNull;
          final latestGoal =
              latestBoard?.goals[position] ?? board.goals[position];
          final allComplete =
              latestGoal.miniGoals.isNotEmpty &&
              latestGoal.miniGoals.every((mg) => mg.isComplete);
          final colorScheme = Theme.of(sheetContext).colorScheme;
          final effs = _effectivePercentages(latestGoal.miniGoals);

          return StyledBottomSheetContent(
            title: latestGoal.title ?? 'Goal',
            showClose: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: latestGoal.progress / 100,
                          minHeight: 6,
                          backgroundColor: colorScheme.onSurface.withValues(
                            alpha: 0.08,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${latestGoal.progress}%',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Custom milestone rows
                ...latestGoal.miniGoals.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        // Circle toggle with loading
                        ValueListenableBuilder<String?>(
                          valueListenable: togglingMgId,
                          builder: (_, toggling, _) {
                            final isLoading = toggling == e.value.id;
                            return GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () async {
                                      togglingMgId.value = e.value.id;
                                      try {
                                        await ref
                                            .read(boardActionsProvider)
                                            .toggleMiniGoal(
                                              widget.boardId,
                                              position,
                                              e.value.id,
                                            );
                                      } catch (err) {
                                        _showError(err);
                                      } finally {
                                        togglingMgId.value = null;
                                      }
                                    },
                              child: SizedBox(
                                width: 26,
                                height: 26,
                                child: isLoading
                                    ? CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: colorScheme.primary,
                                      )
                                    : AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: e.value.isComplete
                                                ? colorScheme.primary
                                                : colorScheme.onSurface
                                                      .withValues(alpha: 0.25),
                                            width: 1.5,
                                          ),
                                          color: e.value.isComplete
                                              ? colorScheme.primary
                                              : Colors.transparent,
                                        ),
                                        child: e.value.isComplete
                                            ? Icon(
                                                Icons.check,
                                                size: 15,
                                                color: colorScheme.onPrimary,
                                              )
                                            : null,
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 14),
                        // Title + percentage
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.value.title,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: e.value.isComplete
                                      ? colorScheme.onSurface.withValues(
                                          alpha: 0.4,
                                        )
                                      : colorScheme.onSurface,
                                  decoration: e.value.isComplete
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatPct(effs[e.key]),
                                style: AppTypography.caption.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.35,
                                  ),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GradientButton(
                  label: allComplete
                      ? 'Complete Goal!'
                      : 'Complete all milestones first',
                  onPressed: allComplete
                      ? () {
                          Navigator.pop(sheetContext);
                          _showIconPhotoPicker(position, completeFirst: true);
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
    '🏆',
    '⭐',
    '🔥',
    '🎯',
    '💪',
    '📚',
    '🎨',
    '🏃',
    '💰',
    '🧘',
    '✈️',
    '🎵',
    '💡',
    '🌱',
    '❤️',
    '🎉',
    '🏠',
    '🍎',
    '⚡',
    '🌟',
    '🎓',
    '💼',
    '🏋️',
    '🧠',
    '🌍',
    '📝',
    '🔑',
    '🎭',
    '🚀',
    '👑',
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
        HapticFeedback.heavyImpact();
        _confettiController.play();
        final milestones =
            (result['milestones'] as List?)?.cast<String>() ?? [];
        if (milestones.isNotEmpty) {
          _showMilestoneCelebration(
            milestones,
            result['gemsAwarded'] as int? ?? 0,
          );
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
                    color: Theme.of(
                      sheetContext,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
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
                      await ref
                          .read(boardActionsProvider)
                          .updateGoalIcon(
                            widget.boardId,
                            position,
                            icon: _celebrationIcons[i],
                          );
                    } catch (e) {
                      _showError(e);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        sheetContext,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _celebrationIcons[i],
                        style: const TextStyle(fontSize: 24),
                      ),
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
      await ref
          .read(boardActionsProvider)
          .addGoalMemory(widget.boardId, position, image.path);
    } catch (e) {
      _showError(e);
    }
  }

  void _showInviteSheet() async {
    // Generate invite immediately, then show the code
    try {
      final invite = await ref
          .read(boardActionsProvider)
          .createInvite(widget.boardId);
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
                  color: Theme.of(
                    sheetContext,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    sheetContext,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      sheetContext,
                    ).colorScheme.primary.withValues(alpha: 0.3),
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
                        color: Theme.of(
                          sheetContext,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
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
                    Clipboard.setData(ClipboardData(text: invite.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite code copied!')),
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
    final isOwner = board.members.any(
      (m) => m.id == currentUserId && m.isOwner,
    );

    showStyledBottomSheet(
      context: context,
      builder: (sheetContext) => StyledBottomSheetContent(
        title: 'Members (${board.members.length})',
        showClose: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...board.members.map(
              (member) => Padding(
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
                              color: Theme.of(
                                sheetContext,
                              ).colorScheme.onSurface,
                            ),
                          ),
                          if (member.isOwner)
                            Text(
                              'Owner',
                              style: AppTypography.caption.copyWith(
                                color: Theme.of(
                                  sheetContext,
                                ).colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isOwner &&
                        !member.isOwner &&
                        member.id != currentUserId)
                      IconButton(
                        icon: Icon(
                          Icons.person_remove_outlined,
                          size: 20,
                          color: Theme.of(sheetContext).colorScheme.error,
                        ),
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          try {
                            await ref
                                .read(boardActionsProvider)
                                .removeMember(widget.boardId, member.id);
                          } catch (e) {
                            _showError(e);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
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
                    foregroundColor: Theme.of(sheetContext).colorScheme.error,
                    side: BorderSide(
                      color: Theme.of(sheetContext).colorScheme.error,
                    ),
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
    final notes = _notesController.text.trim();
    final victories = _victoriesController.text.trim();
    final obstacles = _obstaclesController.text.trim();
    Navigator.pop(context);
    try {
      final actions = ref.read(boardActionsProvider);
      await actions.updateGoalTitle(widget.boardId, position, title);
      if (notes.isNotEmpty || victories.isNotEmpty || obstacles.isNotEmpty) {
        await actions.upsertReflection(
          widget.boardId,
          position,
          notes: notes.isEmpty ? null : notes,
          victories: victories.isEmpty ? null : victories,
          obstacles: obstacles.isEmpty ? null : obstacles,
        );
      }
    } catch (e) {
      _showError(e);
    }
  }

  Widget _buildReflectionField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required ColorScheme colorScheme,
  }) {
    return StyledTextField(
      controller: controller,
      maxLines: 2,
      hintText: hintText,
      prefixIcon: prefixIcon,
    );
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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

  Widget _buildMemberAvatars(
    List<MemberInfo> members,
    ColorScheme colorScheme,
  ) {
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
          final activity = sheetRef.watch(
            boardActivityProvider(widget.boardId),
          );
          return StyledBottomSheetContent(
            title: 'Activity',
            showClose: true,
            child: activity.when(
              loading: () => const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const SizedBox(
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
                          color: Theme.of(
                            sheetContext,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
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
                          Icon(
                            icon,
                            size: 18,
                            color: Theme.of(sheetContext).colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  desc,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Theme.of(
                                      sheetContext,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  ago,
                                  style: AppTypography.caption.copyWith(
                                    color: Theme.of(sheetContext)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.4),
                                    fontSize: 11,
                                  ),
                                ),
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
            child: Hero(
              tag: 'board-grid-${board.id}',
              child: GoalGrid(
                goals: board.goals,
                gridSize: board.gridSize,
                onCellTap: (index) {
                  HapticFeedback.lightImpact();
                  _showGoalDialog(board, index);
                },
                onCellLongPress: (index) async {
                  final goal = board.goals[index];
                  if (goal.isEmpty) return;

                  HapticFeedback.mediumImpact();

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
        crossAxisSpacing: 20,
        mainAxisSpacing: 24,
        childAspectRatio: 0.8,
      ),
      itemCount: completedGoals.length,
      itemBuilder: (context, index) {
        final goal = completedGoals[index];
        return _buildVisionCard(goal, colorScheme, index);
      },
    );
  }

  Widget _buildVisionCard(Goal goal, ColorScheme colorScheme, int index) {
    const angles = <double>[-0.04, 0.03, -0.025, 0.045, -0.02, 0.035];
    final angle = angles[index % angles.length];

    final boardMemory = goal.memories.where((m) => m.isBoardImage).firstOrNull;
    final boardImageUrl = boardMemory?.imageUrl ?? goal.imageUrl ?? '';
    final caption = boardMemory != null && boardMemory.label.isNotEmpty
        ? boardMemory.label
        : goal.title ?? 'Goal';

    final hasPhoto = boardImageUrl.isNotEmpty;
    final hasIcon = goal.icon != null && goal.icon!.isNotEmpty;

    String formattedDate = '';
    if (goal.completedAt != null) {
      const months = [
        'JAN',
        'FEB',
        'MAR',
        'APR',
        'MAY',
        'JUN',
        'JUL',
        'AUG',
        'SEP',
        'OCT',
        'NOV',
        'DEC',
      ];
      formattedDate =
          '${months[goal.completedAt!.month - 1]} ${goal.completedAt!.day}';
    }

    return Transform.rotate(
      angle: angle,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: colorScheme.onSurface.withValues(alpha: 0.06),
                ),
                child: hasPhoto
                    ? _buildVisionCardPhoto(boardImageUrl)
                    : Center(
                        child: hasIcon
                            ? Text(
                                goal.icon!,
                                style: const TextStyle(fontSize: 48),
                              )
                            : Icon(
                                Icons.check_circle,
                                size: 48,
                                color: colorScheme.primary,
                              ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caption,
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (formattedDate.isNotEmpty)
                        Text(
                          formattedDate,
                          style: AppTypography.caption.copyWith(
                            color: Colors.black38,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      const Spacer(),
                      const Icon(
                        Icons.check_circle,
                        size: 13,
                        color: Color(0xFF7CA982),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisionCardPhoto(String imageUrl) {
    final fullUrl = imageUrl.startsWith('http')
        ? imageUrl
        : '${ApiConstants.baseUrl}$imageUrl';
    return CachedNetworkImage(
      imageUrl: fullUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, _) => Container(
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (_, _, _) => Container(
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add comment')));
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
            Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: colorScheme.primary,
            ),
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
                        horizontal: 6,
                        vertical: 2,
                      ),
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
              error: (_, _) => const SizedBox.shrink(),
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
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
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
                          icon: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            try {
                              await ref
                                  .read(boardActionsProvider)
                                  .deleteComment(widget.goalId, comment.id);
                            } catch (_) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to delete comment'),
                                  ),
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
          error: (_, _) => Text(
            'Failed to load comments',
            style: AppTypography.bodySmall.copyWith(color: colorScheme.error),
          ),
        ),
      ],
    );
  }
}

// ── Mood color helpers ────────────────────────────────────────────────────────

const _moodColors = {
  'sage': Color(0xFF7CA982),
  'terracotta': Color(0xFFBF6B52),
  'slate': Color(0xFF6B8CAE),
  'sunrise': Color(0xFFD4A847),
};

Color _moodColor(String? mood, ColorScheme colorScheme) {
  if (mood == null) return colorScheme.primary.withValues(alpha: 0.65);
  return (_moodColors[mood] ?? colorScheme.primary).withValues(alpha: 0.85);
}

class _MoodPicker extends StatelessWidget {
  final String? currentMood;
  final void Function(String?) onMoodSelected;

  const _MoodPicker({required this.currentMood, required this.onMoodSelected});

  @override
  Widget build(BuildContext context) {
    final moods = [
      ('sage', const Color(0xFF7CA982), 'Sage'),
      ('terracotta', const Color(0xFFBF6B52), 'Terracotta'),
      ('slate', const Color(0xFF6B8CAE), 'Slate'),
      ('sunrise', const Color(0xFFD4A847), 'Sunrise'),
    ];

    return Row(
      children: moods.map((m) {
        final isSelected = currentMood == m.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GestureDetector(
            onTap: () => onMoodSelected(isSelected ? null : m.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isSelected ? 30 : 26,
              height: isSelected ? 30 : 26,
              decoration: BoxDecoration(
                color: m.$2,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: m.$2.withValues(alpha: 0.4), width: 3)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: m.$2.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
