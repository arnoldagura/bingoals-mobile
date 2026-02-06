import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/boards_api.dart';
import '../models/models.dart';

/// Board summaries from API (for dashboard)
final boardSummariesProvider = FutureProvider<List<BoardSummary>>((ref) async {
  final api = ref.watch(boardsApiProvider);
  return api.getBoards();
});

/// Full board with goals from API (for board screen)
final boardDetailProvider =
    FutureProvider.family<Board, String>((ref, boardId) async {
  final api = ref.watch(boardsApiProvider);
  return api.getBoard(boardId);
});

/// Dashboard stats derived from board summaries
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final summariesAsync = ref.watch(boardSummariesProvider);
  return summariesAsync.when(
    data: (summaries) {
      final totalGoals =
          summaries.fold<int>(0, (sum, b) => sum + b.goalCount);
      final completedGoals =
          summaries.fold<int>(0, (sum, b) => sum + b.completedCount);
      return DashboardStats(
        totalGoals: totalGoals,
        completedGoals: completedGoals,
        overallProgress: totalGoals > 0
            ? ((completedGoals / totalGoals) * 100).round()
            : 0,
        totalGems: completedGoals * 3,
        activeBoards: summaries.length,
        year: DateTime.now().year,
      );
    },
    loading: () => DashboardStats.empty(),
    error: (_, __) => DashboardStats.empty(),
  );
});

/// Board mutations — call API then invalidate providers to refetch
final boardActionsProvider = Provider<BoardActions>((ref) {
  return BoardActions(ref);
});

class BoardActions {
  final Ref _ref;

  BoardActions(this._ref);

  BoardsApi get _api => _ref.read(boardsApiProvider);

  Future<Board> createBoard(String title) async {
    final board = await _api.createBoard(title: title);
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
      String boardId, int position, String title) async {
    await _api.updateGoal(boardId, position, title: title);
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(boardSummariesProvider);
  }

  Future<void> toggleGoalCompletion(String boardId, int position) async {
    await _api.toggleGoal(boardId, position);
    _ref.invalidate(boardDetailProvider(boardId));
    _ref.invalidate(boardSummariesProvider);
  }
}

/// Stats data class for dashboard
class DashboardStats {
  final int totalGoals;
  final int completedGoals;
  final int overallProgress;
  final int totalGems;
  final int activeBoards;
  final int year;

  const DashboardStats({
    required this.totalGoals,
    required this.completedGoals,
    required this.overallProgress,
    required this.totalGems,
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
