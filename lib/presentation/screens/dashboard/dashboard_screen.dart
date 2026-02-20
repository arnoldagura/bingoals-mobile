import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/board_categories.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/boards_provider.dart';
import '../../../data/providers/notifications_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_button.dart';
import '../../widgets/common/gradient_mesh_background.dart';
import '../../widgets/common/styled_bottom_sheet.dart';
import '../../widgets/common/styled_text_field.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/dashboard/board_card.dart';
import '../../widgets/dashboard/dashboard_stats.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  final _newBoardController = TextEditingController();
  int _selectedGridSize = 5;
  String? _selectedCategory;
  String? _filterCategory;
  String? _nameErrorText;
  String _boardType = 'personal';
  int _maxMembers = 5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _newBoardController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh notification count when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationsProvider);
    }
  }

  void _showCreateBoardDialog() {
    _newBoardController.clear();
    _selectedGridSize = 5;
    _selectedCategory = null;
    _nameErrorText = null;
    _boardType = 'personal';
    _maxMembers = 5;

    showStyledBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => StyledBottomSheetContent(
          title: 'Create New Board',
          showClose: true,
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Start',
                style: AppTypography.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BoardPreset.all.map((preset) {
                  return GestureDetector(
                    onTap: () => setDialogState(() {
                      _newBoardController.text = preset.suggestedTitle;
                      _selectedCategory = preset.category;
                      _boardType = preset.boardType;
                      _maxMembers = preset.maxMembers;
                      _selectedGridSize = preset.gridSize;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: preset.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: preset.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(preset.icon, size: 16, color: preset.color),
                          const SizedBox(width: 4),
                          Text(
                            preset.label,
                            style: AppTypography.caption.copyWith(
                              color: preset.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              StyledTextField(
                controller: _newBoardController,
                autofocus: true,
                hintText: 'e.g., Career Goals 2026',
                labelText: 'Board Name',
                prefixIcon: Icons.dashboard_outlined,
                onChanged: (value) {
                  if (_nameErrorText != null) {
                    setDialogState(() => _nameErrorText = null);
                  }
                },
              ),
              if (_nameErrorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    _nameErrorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Category',
                style: AppTypography.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: BoardCategory.all.map((cat) {
                  final isSelected = _selectedCategory == cat.key;
                  return GestureDetector(
                    onTap: () => setDialogState(() =>
                        _selectedCategory =
                            isSelected ? null : cat.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? cat.color.withValues(alpha: 0.15)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? cat.color
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat.icon, size: 16, color: cat.color),
                          const SizedBox(width: 4),
                          Text(
                            cat.label,
                            style: AppTypography.caption.copyWith(
                              color: isSelected
                                  ? cat.color
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Grid Size',
                style: AppTypography.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [3, 5, 7].map((size) {
                  final isSelected = _selectedGridSize == size;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: size == 7 ? 0 : 8,
                      ),
                      child: GestureDetector(
                        onTap: () => setDialogState(
                            () => _selectedGridSize = size),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${size}x$size',
                                style: AppTypography.labelLarge.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${size * size} goals',
                                style: AppTypography.caption.copyWith(
                                  color: isSelected
                                      ? Colors.white70
                                      : Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'Board Type',
                style: AppTypography.labelMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => _boardType = 'personal'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _boardType == 'personal'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _boardType == 'personal'
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 20,
                              color: _boardType == 'personal'
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Personal',
                              style: AppTypography.labelLarge.copyWith(
                                color: _boardType == 'personal'
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setDialogState(() => _boardType = 'shared'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _boardType == 'shared'
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _boardType == 'shared'
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.group_outlined,
                              size: 20,
                              color: _boardType == 'shared'
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Shared',
                              style: AppTypography.labelLarge.copyWith(
                                color: _boardType == 'shared'
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_boardType == 'shared') ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Max Members',
                      style: AppTypography.labelMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '$_maxMembers',
                      style: AppTypography.labelLarge.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _maxMembers.toDouble(),
                  min: 2,
                  max: 10,
                  divisions: 8,
                  label: '$_maxMembers',
                  onChanged: (v) => setDialogState(() => _maxMembers = v.round()),
                ),
              ],
              const SizedBox(height: 24),
              GradientButton(
                label: 'Create Board',
                icon: Icons.add,
                onPressed: () {
                  final title = _newBoardController.text.trim();
                  if (title.isEmpty) {
                    setDialogState(() => _nameErrorText = 'Board Name cannot be empty');
                  } else {
                    _createBoard();
                  }
                },
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Future<void> _createBoard() async {
    final title = _newBoardController.text.trim();
    if (title.isEmpty) return;

    Navigator.pop(context);
    final board = await ref.read(boardActionsProvider).createBoard(
          title,
          gridSize: _selectedGridSize,
          category: _selectedCategory,
          boardType: _boardType,
          maxMembers: _boardType == 'shared' ? _maxMembers : 5,
        );
    if (mounted) context.go('/board/${board.id}');
  }

  void _showJoinBoardDialog() {
    final codeController = TextEditingController();
    String? errorText;

    showStyledBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => StyledBottomSheetContent(
          title: 'Join a Board',
          showClose: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StyledTextField(
                controller: codeController,
                autofocus: true,
                hintText: 'e.g., ABC123',
                labelText: 'Invite Code',
                prefixIcon: Icons.vpn_key_outlined,
                onChanged: (_) {
                  if (errorText != null) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Join Board',
                icon: Icons.group_add,
                onPressed: () async {
                  final code = codeController.text.trim();
                  if (code.isEmpty) {
                    setDialogState(() => errorText = 'Please enter an invite code');
                    return;
                  }
                  try {
                    final boardId = await ref.read(boardActionsProvider).joinBoard(code);
                    if (context.mounted) {
                      Navigator.pop(context);
                      this.context.push('/board/$boardId');
                    }
                  } catch (e) {
                    setDialogState(() => errorText = 'Invalid or expired invite code');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDialog(String boardId, String currentTitle) {
    _newBoardController.text = currentTitle;
    _nameErrorText = null;

    showStyledBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => StyledBottomSheetContent(
          title: 'Rename Board',
          showClose: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StyledTextField(
                controller: _newBoardController,
                autofocus: true,
                labelText: 'Board Name',
                prefixIcon: Icons.edit_outlined,
                onChanged: (value) {
                  if (_nameErrorText != null) {
                    setDialogState(() => _nameErrorText = null);
                  }
                },
              ),
              if (_nameErrorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _nameErrorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              GradientButton(
                label: 'Rename',
                onPressed: () async {
                  final newTitle = _newBoardController.text.trim();
                  if (newTitle.isEmpty) {
                    setDialogState(() => _nameErrorText = 'Name cannot be empty');
                    return;
                  }
                  Navigator.pop(context);
                  await ref.read(boardActionsProvider).renameBoard(boardId, newTitle);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _confirmDelete(String boardId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Board?'),
        content: const Text(
          'This action cannot be undone. All goals in this board will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(boardActionsProvider).deleteBoard(boardId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final boardsAsync = ref.watch(boardSummariesProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GradientMeshScaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Boards',
                            style: AppTypography.displaySmall.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            authState.user != null
                                ? 'Hey ${authState.user!.displayLabel} · ${Helpers.currentYear}'
                                : '${Helpers.currentYear}',
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    UserAvatar(
                      imageUrl: authState.user?.avatarUrl,
                      initials: authState.user?.initials ?? '?',
                      radius: 20,
                      onTap: () => context.go('/settings'),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: DashboardStatsGrid(stats: stats),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Boards',
                      style: AppTypography.headlineSmall.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showJoinBoardDialog,
                          icon: const Icon(Icons.group_add, size: 18),
                          label: const Text('Join'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _showCreateBoardDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: _filterCategory == null,
                        onSelected: (_) =>
                            setState(() => _filterCategory = null),
                      ),
                    ),
                    ...BoardCategory.all.map((cat) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Icon(cat.icon, size: 16, color: cat.color),
                            label: Text(cat.label),
                            selected: _filterCategory == cat.key,
                            onSelected: (_) => setState(() =>
                                _filterCategory =
                                    _filterCategory == cat.key
                                        ? null
                                        : cat.key),
                          ),
                        )),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            boardsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 12),
                        Text('Failed to load boards',
                            style: AppTypography.bodyMedium),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(boardSummariesProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (boards) {
                if (boards.isEmpty) {
                  return SliverToBoxAdapter(
                      child: _buildEmptyState(colorScheme));
                }
                final filtered = _filterCategory == null
                    ? boards
                    : boards
                        .where((b) => b.category == _filterCategory)
                        .toList();
                if (filtered.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(
                          'No boards in this category',
                          style: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final board = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: BoardCard(
                            board: board,
                            onTap: () =>
                                context.push('/board/${board.id}'),
                            onRename: () =>
                                _showRenameDialog(board.id, board.title),
                            onDelete: () => _confirmDelete(board.id),
                            onSetDefault: () {
                              ref
                                  .read(boardActionsProvider)
                                  .setDefaultBoard(board.id);
                            },
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.dashboard_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create Your First Board',
              style: AppTypography.headlineSmall.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your goals with a beautiful goal board.',
              style: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GradientButton(
              label: 'Create Board',
              icon: Icons.add,
              onPressed: _showCreateBoardDialog,
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}

