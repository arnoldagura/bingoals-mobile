import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/boards_api.dart';
import '../models/models.dart';

/// Activity feed for a specific board
final boardActivityProvider =
    FutureProvider.family<ActivityPage, String>((ref, boardId) async {
  final api = ref.watch(boardsApiProvider);
  return api.getActivity(boardId);
});

/// Members list for a specific board
final boardMembersProvider =
    FutureProvider.family<List<MemberInfo>, String>((ref, boardId) async {
  final api = ref.watch(boardsApiProvider);
  return api.getMembers(boardId);
});

/// Reactions for a specific goal
final goalReactionsProvider =
    FutureProvider.family<List<Reaction>, String>((ref, goalId) async {
  final api = ref.watch(boardsApiProvider);
  return api.getReactions(goalId);
});

/// Comments for a specific goal
final goalCommentsProvider =
    FutureProvider.family<List<Comment>, String>((ref, goalId) async {
  final api = ref.watch(boardsApiProvider);
  return api.getComments(goalId);
});
