import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void dispose() {
    _newBoardController.dispose();
    super.dispose();
  }

  void _showCreateBoardDialog() {
    _newBoardController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Board'),
        content: TextField(
          controller: _newBoardController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., Career Goals 2026',
            labelText: 'Board Name',
          ),
          onSubmitted: (_) => _createBoard(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _createBoard,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBoard() async {
    final title = _newBoardController.text.trim();
    if (title.isEmpty) return;

    Navigator.pop(context);
    await ref.read(boardActionsProvider).createBoard(title);
  }

  void _showRenameDialog(String boardId, String currentTitle) {
    _newBoardController.text = currentTitle;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Board'),
        content: TextField(
          controller: _newBoardController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Board Name',
          ),
          onSubmitted: (_) async {
            final newTitle = _newBoardController.text.trim();
            if (newTitle.isNotEmpty) {
              Navigator.pop(context);
              await ref
                  .read(boardActionsProvider)
                  .renameBoard(boardId, newTitle);
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
              if (newTitle.isNotEmpty) {
                Navigator.pop(context);
                await ref
                    .read(boardActionsProvider)
                    .renameBoard(boardId, newTitle);
              }
            },
            child: const Text('Rename'),
          ),
        ],
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
            // Header
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

            // Stats grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: DashboardStatsGrid(stats: stats),
              ),
            ),

            // Boards section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Boards',
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

            // Boards list — async
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
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final board = boards[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: BoardCard(
                            board: board,
                            totalBoards: boards.length,
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
                      childCount: boards.length,
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
