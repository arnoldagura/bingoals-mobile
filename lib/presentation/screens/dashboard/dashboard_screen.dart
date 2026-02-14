import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/board_categories.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/boards_provider.dart';
import '../../widgets/common/glass_card.dart';
import '../../widgets/common/gradient_mesh_background.dart';
import '../../widgets/dashboard/board_card.dart';
import '../../widgets/dashboard/dashboard_stats.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _newBoardController = TextEditingController();
  int _selectedGridSize = 5;
  String? _selectedCategory;
  String? _filterCategory;
  String? _nameErrorText;

  @override
  void dispose() {
    _newBoardController.dispose();
    super.dispose();
  }

  void _showCreateBoardDialog() {
    _newBoardController.clear();
    _selectedGridSize = 5;
    _selectedCategory = null;
    _nameErrorText = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create New Boardsad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _newBoardController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g., Career Goals 2026',
                  labelText: 'Board Name',
                  errorText: _nameErrorText,
                ),
                onChanged: (value) {
                  if (_nameErrorText != null) {
                    setDialogState(() => _nameErrorText = null);
                  }
                },
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = _newBoardController.text.trim();
                if (title.isEmpty) {
                  setDialogState(() => _nameErrorText = 'Board Name cannot be empty');
                } else {
                  _createBoard(); 
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createBoard() async {
    final title = _newBoardController.text.trim();
    if (title.isEmpty) return;

    Navigator.pop(context);
    await ref.read(boardActionsProvider).createBoard(
          title,
          gridSize: _selectedGridSize,
          category: _selectedCategory,
        );
  }

  void _showRenameDialog(String boardId, String currentTitle) {
    _newBoardController.text = currentTitle;
    _nameErrorText = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rename Board'),
          content: TextField(
            controller: _newBoardController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Board Name',
              errorText: _nameErrorText,
            ),
            onChanged: (value) {
              if (_nameErrorText != null) {
                setDialogState(() => _nameErrorText = null);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newTitle = _newBoardController.text.trim();
                if (newTitle.isEmpty) {
                  setDialogState(() => _nameErrorText = 'Name cannot be empty');
                  return;
                }
                Navigator.pop(context);
                await ref.read(boardActionsProvider).renameBoard(boardId, newTitle);
              },
              child: const Text('Rename'),
            ),
          ],
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colorScheme.primary,
        onPressed: _showCreateBoardDialog,
        icon: const Icon(Icons.add),
        foregroundColor: Colors.white,
        label: const Text('New Board'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.user != null
                                ? 'Welcome, ${authState.user!.name.isNotEmpty ? authState.user!.name : 'back'}'
                                : 'Welcome back',
                            style: AppTypography.displaySmall.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Here's how your goals are progressing in ${Helpers.currentYear}",
                            style: AppTypography.bodyMedium.copyWith(
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/settings'),
                      icon: const Icon(Icons.settings_outlined),
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
                      'Your Boardswew',
                      style: AppTypography.headlineSmall.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showCreateBoardDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Board'),
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
                        Text('Failed to load boardssd',
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
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
            ElevatedButton.icon(
              onPressed: _showCreateBoardDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create Board'),
            ),
          ],
        ),
      ),
    );
  }
}
