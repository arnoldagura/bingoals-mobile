import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/boards_api.dart';
import '../models/models.dart';
import 'auth_provider.dart';
import 'shared_board_providers.dart';

final boardSummariesProvider = FutureProvider<List<BoardSummary>>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isLoggedIn) return [];

  final api = ref.watch(boardsApiProvider);
  return api.getBoards();
});

final boardDetailProvider = FutureProvider.family<Board, String>((
  ref,
  boardId,
) async {
  final api = ref.watch(boardsApiProvider);
  return api.getBoard(boardId);
});

final galleryProvider = FutureProvider<List<GalleryItem>>((ref) async {
  final authState = ref.watch(authProvider);
  if (!authState.isLoggedIn) return [];
  final api = ref.watch(boardsApiProvider);
  final raw = await api.getGallery();
  return raw.map(GalleryItem.fromJson).toList();
});

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final summariesAsync = ref.watch(boardSummariesProvider);
  final authState = ref.watch(authProvider);
  return summariesAsync.when(
    data: (summaries) {
      final totalGoals = summaries.fold<int>(0, (sum, b) => sum + b.goalCount);
      final completedGoals = summaries.fold<int>(
        0,
        (sum, b) => sum + b.completedCount,
      );
      return DashboardStats(
        totalGoals: totalGoals,
        completedGoals: completedGoals,
        overallProgress: totalGoals > 0
            ? ((completedGoals / totalGoals) * 100).round()
            : 0,
        totalGems: authState.user?.totalGems ?? 0,
        dailyStreak: authState.user?.dailyStreak ?? 0,
        level: authState.user?.level ?? 'bronze',
        activeBoards: summaries.length,
        year: DateTime.now().year,
      );
    },
    loading: () => DashboardStats.empty(),
    error: (_, _) => DashboardStats.empty(),
  );
});

final boardActionsProvider = Provider<BoardActions>((ref) {
  return BoardActions(ref);
});

class BoardActions {
  final Ref _ref;

  BoardActions(this._ref);

  BoardsApi get _api => _ref.read(boardsApiProvider);

  Future<Board> createBoard(
    String title, {
    int gridSize = 5,
    String? category,
    String boardType = 'personal',
    int maxMembers = 5,
  }) async {
    final board = await _api.createBoard(
      title: title,
      gridSize: gridSize,
      category: category,
      boardType: boardType,
      maxMembers: maxMembers,
    );
    _ref.invalidate(boardSummariesProvider);
    return board;
  }

  Future<void> deleteBoard(String boardId) async {
    await _api.deleteBoard(boardId);
    _ref.invalidate(boardSummariesProvider);
  }

  Future<void> renameBoard(String boardId, String newTitle) async {
    await _api.updateBoard(boardId, title: newTitle);
    _ref.invalidate(boardSummariesProvider);
  }

  Future<void> setDefaultBoard(String boardId) async {
    await _api.updateBoard(boardId, isDefault: true);
    _ref.invalidate(boardSummariesProvider);
  }

  Future<void> updateGoalTitle(
    String boardId,
    int position,
    String title,
  ) async {
    await _api.updateGoal(boardId, position, title: title);
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(boardSummariesProvider);
  }

  Future<void> clearGoal(String boardId, int position) async {
    await _api.clearGoal(boardId, position);
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(boardSummariesProvider);
  }

  Future<Map<String, dynamic>> toggleGoalCompletion(
    String boardId,
    int position,
  ) async {
    final result = await _api.toggleGoal(boardId, position);
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(boardSummariesProvider);
    _ref.read(authProvider.notifier).refreshUser();
    return result;
  }

  Future<void> createMiniGoal(
    String boardId,
    int position, {
    required String title,
    int? percentage,
  }) async {
    await _api.createMiniGoal(
      boardId,
      position,
      title: title,
      percentage: percentage,
    );
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(boardSummariesProvider);
  }

  Future<void> toggleMiniGoal(
    String boardId,
    int position,
    String miniGoalId,
  ) async {
    await _api.toggleMiniGoal(boardId, position, miniGoalId);
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(boardSummariesProvider);
  }

  Future<void> updateMiniGoal(
    String boardId,
    int position,
    String miniGoalId, {
    String? title,
    int? percentage,
  }) async {
    await _api.updateMiniGoal(
      boardId,
      position,
      miniGoalId,
      title: title,
      percentage: percentage,
    );
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(boardSummariesProvider);
  }

  Future<void> deleteMiniGoal(
    String boardId,
    int position,
    String miniGoalId,
  ) async {
    await _api.deleteMiniGoal(boardId, position, miniGoalId);
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(boardSummariesProvider);
  }

  Future<void> updateGoalIcon(
    String boardId,
    int position, {
    String? icon,
    String? imageUrl,
  }) async {
    await _api.updateGoalIcon(
      boardId,
      position,
      icon: icon,
      imageUrl: imageUrl,
    );
    _ref.invalidate(boardDetailProvider(boardId));
  }

  Future<String> uploadGoalImage(
    String boardId,
    int position,
    String filePath,
  ) async {
    final url = await _api.uploadImage(filePath);
    await _api.updateGoalIcon(boardId, position, imageUrl: url);
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(galleryProvider);
    return url;
  }

  Future<void> upsertReflection(
    String boardId,
    int position, {
    String? obstacles,
    String? victories,
    String? notes,
    String? reflectionAnswer,
  }) async {
    await _api.upsertReflection(
      boardId,
      position,
      obstacles: obstacles,
      victories: victories,
      notes: notes,
      reflectionAnswer: reflectionAnswer,
    );
    _ref.invalidate(boardDetailProvider(boardId));
  }

  Future<String> uploadImage(String filePath) => _api.uploadImage(filePath);

  // --- Goal memories ---

  Future<void> addGoalMemory(
    String boardId,
    int position,
    String filePath, {
    String label = '',
  }) async {
    final url = await _api.uploadImage(filePath);
    await _api.createGoalMemory(boardId, position, url, label: label);
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(galleryProvider);
  }

  Future<void> deleteGoalMemory(
      String boardId, int position, String memoryId) async {
    await _api.deleteGoalMemory(boardId, position, memoryId);
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(galleryProvider);
  }

  Future<void> setGoalBoardImage(
      String boardId, int position, String memoryId) async {
    await _api.updateGoalMemory(boardId, position, memoryId,
        isBoardImage: true);
    _ref.invalidate(boardDetailProvider(boardId));
  }

  Future<void> updateGoalMemoryLabel(
      String boardId, int position, String memoryId, String label) async {
    await _api.updateGoalMemory(boardId, position, memoryId, label: label);
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(galleryProvider);
  }

  Future<void> updateGoalMood(
    String boardId,
    int position,
    String? mood,
  ) async {
    await _api.updateGoalMood(boardId, position, mood);
    _ref.invalidate(boardDetailProvider(boardId));
  }

  Future<void> updateMilestoneImage(
    String boardId,
    int position,
    String miniGoalId,
    String imageUrl,
  ) async {
    await _api.updateMilestoneImage(boardId, position, miniGoalId, imageUrl);
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(galleryProvider);
  }

  // --- Shared board actions ---

  Future<BoardInvite> createInvite(String boardId) async {
    final invite = await _api.createInvite(boardId);
    return invite;
  }

  Future<String> joinBoard(String inviteCode) async {
    final boardId = await _api.joinBoard(inviteCode);
    _ref.invalidate(boardSummariesProvider);
    return boardId;
  }

  Future<void> leaveBoard(String boardId) async {
    await _api.leaveBoard(boardId);
    _ref.invalidate(boardSummariesProvider);
  }

  Future<void> removeMember(String boardId, String userId) async {
    await _api.removeMember(boardId, userId);
    _ref.invalidate(boardDetailProvider(boardId));
  }

  Future<Map<String, dynamic>> addReaction(String goalId, String type) async {
    final result = await _api.addReaction(goalId, type);
    return result;
  }

  Future<Comment> addComment(String goalId, String text) async {
    final comment = await _api.addComment(goalId, text);
    _ref.invalidate(goalCommentsProvider(goalId));
    return comment;
  }

  Future<void> deleteComment(String goalId, String commentId) async {
    await _api.deleteComment(goalId, commentId);
    _ref.invalidate(goalCommentsProvider(goalId));
  }
}

class DashboardStats {
  final int totalGoals;
  final int completedGoals;
  final int overallProgress;
  final int totalGems;
  final int dailyStreak;
  final String level;
  final int activeBoards;
  final int year;

  const DashboardStats({
    required this.totalGoals,
    required this.completedGoals,
    required this.overallProgress,
    required this.totalGems,
    this.dailyStreak = 0,
    this.level = 'bronze',
    required this.activeBoards,
    required this.year,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalGoals: 0,
      completedGoals: 0,
      overallProgress: 0,
      totalGems: 0,
      activeBoards: 0,
      year: DateTime.now().year,
    );
  }
}
