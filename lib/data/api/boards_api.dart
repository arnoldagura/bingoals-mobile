import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../models/board.dart';
import '../models/board_invite.dart';
import '../models/activity.dart';
import '../models/reaction.dart';
import '../models/comment.dart';
import '../models/goal_memory.dart';
import '../models/journal_entry.dart';
import '../models/mini_goal.dart';
import '../models/reflection.dart';
import 'api_client.dart';


final boardsApiProvider = Provider<BoardsApi>((ref) {
  return BoardsApi(ref.watch(apiClientProvider));
});

class BoardsApi {
  final Dio _dio;

  BoardsApi(this._dio);


  Future<List<BoardSummary>> getBoards() async {
    final response = await _dio.get(ApiConstants.boards);
    final list = response.data as List;
    
    return list
        .map((json) => BoardSummary.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Board> getBoard(String id) async {
    final response = await _dio.get(ApiConstants.board(id));
    return Board.fromJson(response.data);
  }

  Future<Board> createBoard({
    required String title,
    int? year,
    int gridSize = 5,
    String? category,
    String boardType = 'personal',
    int maxMembers = 5,
  }) async {
    final response = await _dio.post(
      ApiConstants.boards,
      data: {
        'title': title,
        'year': ?year,
        'gridSize': gridSize,
        'category': ?category,
        'boardType': boardType,
        'maxMembers': maxMembers,
      },
    );
    return Board.fromJson(response.data);
  }

  Future<void> updateBoard(
    String id, {
    String? title,
    bool? isDefault,
  }) async {
    await _dio.put(
      ApiConstants.board(id),
      data: {
        'title': ?title,
        'isDefault': ?isDefault,
      },
    );
  }

  Future<void> deleteBoard(String id) async {
    await _dio.delete(ApiConstants.board(id));
  }

  Future<void> updateGoal(
    String boardId,
    int position, {
    String? title,
    String? description,
    String? imageUrl,
    bool? isCompleted,
  }) async {
    await _dio.put(
      ApiConstants.updateGoal(boardId, position),
      data: {
        'title': ?title,
        'description': ?description,
        'imageUrl': ?imageUrl,
        'isCompleted': ?isCompleted,
      },
    );
  }

  Future<Map<String, dynamic>> toggleGoal(
      String boardId, int position) async {
    final response =
        await _dio.post(ApiConstants.toggleGoal(boardId, position));
    return response.data as Map<String, dynamic>;
  }

  Future<MiniGoal> createMiniGoal(
    String boardId,
    int position, {
    required String title,
    int? percentage,
  }) async {
    final body = <String, dynamic>{'title': title};
    if (percentage != null) body['percentage'] = percentage;
    final response = await _dio.post(
      ApiConstants.miniGoals(boardId, position),
      data: body,
    );
    return MiniGoal.fromJson(response.data);
  }

  Future<MiniGoal> toggleMiniGoal(
      String boardId, int position, String miniGoalId) async {
    final response = await _dio.post(
      ApiConstants.toggleMiniGoal(boardId, position, miniGoalId),
    );
    return MiniGoal.fromJson(response.data);
  }

  Future<MiniGoal> updateMiniGoal(
    String boardId,
    int position,
    String miniGoalId, {
    String? title,
    int? percentage,
    String? imageUrl,
  }) async {
    final response = await _dio.put(
      ApiConstants.miniGoal(boardId, position, miniGoalId),
      data: {
        'title': ?title,
        'percentage': ?percentage,
        'imageUrl': ?imageUrl,
      },
    );
    return MiniGoal.fromJson(response.data);
  }

  Future<void> deleteMiniGoal(
      String boardId, int position, String miniGoalId) async {
    await _dio.delete(
      ApiConstants.miniGoal(boardId, position, miniGoalId),
    );
  }

  Future<Reflection> upsertReflection(
    String boardId,
    int position, {
    String? obstacles,
    String? victories,
    String? notes,
    String? reflectionAnswer,
  }) async {
    final response = await _dio.put(
      ApiConstants.reflection(boardId, position),
      data: {
        'obstacles': ?obstacles,
        'victories': ?victories,
        'notes': ?notes,
        'reflectionAnswer': ?reflectionAnswer,
      },
    );
    return Reflection.fromJson(response.data);
  }

  /// Clear a goal (reset tile to empty)
  Future<void> clearGoal(String boardId, int position) async {
    await _dio.put(
      ApiConstants.updateGoal(boardId, position),
      data: {
        'title': '',
        'icon': '',
        'imageUrl': '',
        'isCompleted': false,
      },
    );
  }

  /// Upload an image file and return the URL
  Future<String> uploadImage(String filePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post(ApiConstants.upload, data: formData);
    return response.data['url'] as String;
  }

  /// Update a goal's icon and/or imageUrl
  Future<void> updateGoalIcon(
    String boardId,
    int position, {
    String? icon,
    String? imageUrl,
  }) async {
    await _dio.put(
      ApiConstants.updateGoal(boardId, position),
      data: {
        'icon': ?icon,
        'imageUrl': ?imageUrl,
      },
    );
  }

  /// Update a goal's mood color
  Future<void> updateGoalMood(
    String boardId,
    int position,
    String? mood,
  ) async {
    await _dio.put(
      ApiConstants.updateGoal(boardId, position),
      data: {'mood': mood},
    );
  }

  /// Update a milestone's imageUrl
  Future<MiniGoal> updateMilestoneImage(
    String boardId,
    int position,
    String miniGoalId,
    String imageUrl,
  ) async {
    final response = await _dio.put(
      ApiConstants.miniGoal(boardId, position, miniGoalId),
      data: {'imageUrl': imageUrl},
    );
    return MiniGoal.fromJson(response.data);
  }

  // --- Goal memories ---

  Future<GoalMemory> createGoalMemory(
    String boardId,
    int position,
    String imageUrl, {
    String label = '',
  }) async {
    final response = await _dio.post(
      ApiConstants.goalMemories(boardId, position),
      data: {'imageUrl': imageUrl, 'label': label},
    );
    return GoalMemory.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<GoalMemory>> listGoalMemories(
      String boardId, int position) async {
    final response =
        await _dio.get(ApiConstants.goalMemories(boardId, position));
    return (response.data as List)
        .map((m) => GoalMemory.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<GoalMemory> updateGoalMemory(
    String boardId,
    int position,
    String memoryId, {
    String? label,
    bool? isBoardImage,
  }) async {
    final response = await _dio.patch(
      ApiConstants.goalMemory(boardId, position, memoryId),
      data: {
        'label': ?label,
        'isBoardImage': ?isBoardImage,
      },
    );
    return GoalMemory.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteGoalMemory(
      String boardId, int position, String memoryId) async {
    await _dio.delete(ApiConstants.goalMemory(boardId, position, memoryId));
  }

  /// Fetch all milestone memories across all user boards
  Future<List<Map<String, dynamic>>> getGallery() async {
    final response = await _dio.get(ApiConstants.gallery);
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  // --- Shared board methods ---

  /// Create an invite code for a board
  Future<BoardInvite> createInvite(String boardId, {int maxUses = 0, int expiresIn = 0}) async {
    final response = await _dio.post(
      ApiConstants.boardInvites(boardId),
      data: {'maxUses': maxUses, 'expiresIn': expiresIn},
    );
    return BoardInvite.fromJson(response.data);
  }

  /// Join a board via invite code
  Future<String> joinBoard(String inviteCode) async {
    final response = await _dio.post(ApiConstants.joinInvite(inviteCode));
    return response.data['boardId'] as String;
  }

  /// Get members of a board
  Future<List<MemberInfo>> getMembers(String boardId) async {
    final response = await _dio.get(ApiConstants.boardMembers(boardId));
    return (response.data as List)
        .map((m) => MemberInfo.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Remove a member from a board (owner only)
  Future<void> removeMember(String boardId, String userId) async {
    await _dio.delete(ApiConstants.removeMember(boardId, userId));
  }

  /// Leave a board (non-owner)
  Future<void> leaveBoard(String boardId) async {
    await _dio.post(ApiConstants.leaveBoard(boardId));
  }

  /// Get paginated activity feed for a board
  Future<ActivityPage> getActivity(String boardId, {int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      ApiConstants.boardActivity(boardId),
      queryParameters: {'page': page, 'limit': limit},
    );
    return ActivityPage.fromJson(response.data);
  }

  /// Add or toggle a reaction on a goal
  Future<Map<String, dynamic>> addReaction(String goalId, String type) async {
    final response = await _dio.post(
      ApiConstants.goalReactions(goalId),
      data: {'type': type},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get all reactions for a goal
  Future<List<Reaction>> getReactions(String goalId) async {
    final response = await _dio.get(ApiConstants.goalReactions(goalId));
    return (response.data as List)
        .map((r) => Reaction.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Add a comment to a goal
  Future<Comment> addComment(String goalId, String text) async {
    final response = await _dio.post(
      ApiConstants.goalComments(goalId),
      data: {'text': text},
    );
    return Comment.fromJson(response.data);
  }

  /// Get all comments for a goal
  Future<List<Comment>> getComments(String goalId) async {
    final response = await _dio.get(ApiConstants.goalComments(goalId));
    return (response.data as List)
        .map((c) => Comment.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Delete a comment
  Future<void> deleteComment(String goalId, String commentId) async {
    await _dio.delete(ApiConstants.deleteComment(goalId, commentId));
  }

  /// Get the user's journal timeline (completed goals, milestones, reflections)
  Future<List<JournalEntry>> getJournal() async {
    final response = await _dio.get(ApiConstants.journal);
    return (response.data as List)
        .map((j) => JournalEntry.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
