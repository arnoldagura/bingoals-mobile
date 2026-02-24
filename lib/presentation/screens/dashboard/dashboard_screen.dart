import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/board_categories.dart';
import '../../../core/theme/typography.dart';
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
        builder: (context, setDialogState) {
          final cs = Theme.of(context).colorScheme;
          return StyledBottomSheetContent(
            title: 'New Board',
            showClose: true,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Quick start ─────────────────────────────────────────
                  _sectionLabel(cs, 'Quick start'),
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
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
                            width: 120,
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                            decoration: BoxDecoration(
                              color: preset.color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: preset.color.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(preset.icon, color: preset.color, size: 18),
                                const Spacer(),
                                Text(
                                  preset.label,
                                  style: AppTypography.labelMedium.copyWith(
                                    color: cs.onSurface,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${preset.gridSize}×${preset.gridSize} · ${preset.boardType == 'shared' ? 'Shared' : 'Personal'}',
                                  style: AppTypography.caption.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.4),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Board name ──────────────────────────────────────────
                  StyledTextField(
                    controller: _newBoardController,
                    autofocus: true,
                    hintText: 'e.g., Career Goals 2026',
                    labelText: 'Board Name',
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
                        style:
                            TextStyle(color: cs.error, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ── Category ────────────────────────────────────────────
                  _sectionLabel(cs, 'Category'),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.05,
                    children: BoardCategory.all.map((cat) {
                      final isSelected = _selectedCategory == cat.key;
                      return GestureDetector(
                        onTap: () => setDialogState(
                          () => _selectedCategory =
                              isSelected ? null : cat.key,
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color.withValues(alpha: 0.12)
                                : cs.onSurface.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? cat.color.withValues(alpha: 0.5)
                                  : cs.onSurface.withValues(alpha: 0.1),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                cat.icon,
                                size: 18,
                                color: isSelected
                                    ? cat.color
                                    : cs.onSurface.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cat.label,
                                style: AppTypography.caption.copyWith(
                                  color: isSelected
                                      ? cat.color
                                      : cs.onSurface.withValues(alpha: 0.55),
                                  fontSize: 9.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Grid size ───────────────────────────────────────────
                  _sectionLabel(cs, 'Grid size'),
                  Row(
                    children: [3, 5, 7].map((size) {
                      final isSelected = _selectedGridSize == size;
                      final dotColor = isSelected
                          ? cs.onPrimary.withValues(alpha: 0.8)
                          : cs.onSurface.withValues(alpha: 0.18);
                      return Expanded(
                        child: Padding(
                          padding:
                              EdgeInsets.only(right: size == 7 ? 0 : 8),
                          child: GestureDetector(
                            onTap: () => setDialogState(
                                () => _selectedGridSize = size),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primary
                                    : cs.onSurface.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? cs.primary
                                      : cs.onSurface.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Column(
                                children: [
                                  _DotGridPreview(
                                    size: size > 5 ? 5 : size,
                                    dotColor: dotColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '$size×$size',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: isSelected
                                          ? cs.onPrimary
                                          : cs.onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${size * size} goals',
                                    style: AppTypography.caption.copyWith(
                                      color: isSelected
                                          ? cs.onPrimary.withValues(alpha: 0.6)
                                          : cs.onSurface.withValues(alpha: 0.45),
                                      fontSize: 10,
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

                  // ── Board type ──────────────────────────────────────────
                  _sectionLabel(cs, 'Board type'),
                  Row(
                    children: [
                      Expanded(
                        child: _BoardTypeCard(
                          icon: Icons.person_outline,
                          label: 'Personal',
                          subtitle: 'Just for you',
                          isSelected: _boardType == 'personal',
                          onTap: () => setDialogState(
                              () => _boardType = 'personal'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BoardTypeCard(
                          icon: Icons.group_outlined,
                          label: 'Shared',
                          subtitle: 'Invite others',
                          isSelected: _boardType == 'shared',
                          onTap: () => setDialogState(
                              () => _boardType = 'shared'),
                        ),
                      ),
                    ],
                  ),

                  // ── Max members (shared only) ───────────────────────────
                  if (_boardType == 'shared') ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _sectionLabel(cs, 'Max members'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_maxMembers people',
                            style: AppTypography.caption.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
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
                      onChanged: (v) =>
                          setDialogState(() => _maxMembers = v.round()),
                    ),
                  ],
                  const SizedBox(height: 24),
                  GradientButton(
                    label: 'Create Board',
                    icon: Icons.add,
                    onPressed: () {
                      final title = _newBoardController.text.trim();
                      if (title.isEmpty) {
                        setDialogState(
                          () => _nameErrorText =
                              'Board Name cannot be empty',
                        );
                      } else {
                        _createBoard();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createBoard() async {
    final title = _newBoardController.text.trim();
    if (title.isEmpty) return;

    Navigator.pop(context);
    final board = await ref
        .read(boardActionsProvider)
        .createBoard(
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
                    setDialogState(
                      () => errorText = 'Please enter an invite code',
                    );
                    return;
                  }
                  try {
                    final boardId = await ref
                        .read(boardActionsProvider)
                        .joinBoard(code);
                    if (context.mounted) {
                      Navigator.pop(context);
                      this.context.push('/board/$boardId');
                    }
                  } catch (e) {
                    setDialogState(
                      () => errorText = 'Invalid or expired invite code',
                    );
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
                    setDialogState(
                      () => _nameErrorText = 'Name cannot be empty',
                    );
                    return;
                  }
                  Navigator.pop(context);
                  await ref
                      .read(boardActionsProvider)
                      .renameBoard(boardId, newTitle);
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
    final boardsAsync = ref.watch(boardSummariesProvider);
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final now = DateTime.now();
    final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateLabel = '${dayNames[now.weekday - 1].toUpperCase()}, ${monthNames[now.month - 1].toUpperCase()} ${now.day}';

    return GradientMeshScaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBoardDialog,
        backgroundColor: colorScheme.onSurface,
        foregroundColor: colorScheme.surface,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateLabel,
                            style: AppTypography.caption.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.45),
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'My Boards',
                            style: AppTypography.displaySmall.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Badge(
                        isLabelVisible: ref.watch(unreadCountProvider) > 0,
                        label: Text('${ref.watch(unreadCountProvider)}'),
                        child: Icon(
                          Icons.notifications_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      onPressed: () => context.push('/notifications'),
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
                    OutlinedButton.icon(
                      onPressed: _showJoinBoardDialog,
                      icon: const Icon(Icons.group_add, size: 18),
                      label: const Text('Join'),
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
                    ...BoardCategory.all.map(
                      (cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(cat.icon, size: 16, color: cat.color),
                          label: Text(cat.label),
                          selected: _filterCategory == cat.key,
                          onSelected: (_) => setState(
                            () => _filterCategory = _filterCategory == cat.key
                                ? null
                                : cat.key,
                          ),
                        ),
                      ),
                    ),
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
                        Text(
                          'Failed to load boards',
                          style: AppTypography.bodyMedium,
                        ),
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
                    child: _buildEmptyState(colorScheme),
                  );
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
                            color: colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return SliverMainAxisGroup(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final board = filtered[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: BoardCard(
                              board: board,
                              onTap: () => context.push('/board/${board.id}'),
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
                        }, childCount: filtered.length),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                        child: Text(
                          'Start your next chapter...',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Widget _sectionLabel(ColorScheme cs, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: cs.onSurface.withValues(alpha: 0.4),
          fontSize: 10,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
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

// ── Private helpers for the create-board form ─────────────────────────────

class _DotGridPreview extends StatelessWidget {
  final int size;
  final Color dotColor;

  const _DotGridPreview({required this.size, required this.dotColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        size,
        (row) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            size,
            (col) => Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: dotColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _BoardTypeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? cs.primary
                : cs.onSurface.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? cs.onPrimary
                  : cs.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? cs.onPrimary : cs.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? cs.onPrimary.withValues(alpha: 0.65)
                        : cs.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
