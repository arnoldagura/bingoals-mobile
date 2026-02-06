import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../models/board.dart';
import 'api_client.dart';

/// Boards API service
final boardsApiProvider = Provider<BoardsApi>((ref) {
  return BoardsApi(ref.watch(apiClientProvider));
});

class BoardsApi {
  final Dio _dio;

  BoardsApi(this._dio);

  /// Get all boards (returns summaries)
  Future<List<BoardSummary>> getBoards() async {
    final response = await _dio.get(ApiConstants.boards);
    final list = response.data as List;
    return list
        .map((json) => BoardSummary.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get a single board with all goals
  Future<Board> getBoard(String id) async {
    final response = await _dio.get(ApiConstants.board(id));
    return Board.fromJson(response.data);
  }

  /// Create a new board
  Future<Board> createBoard({required String title, int? year}) async {
    final response = await _dio.post(
      ApiConstants.boards,
      data: {'title': title, if (year != null) 'year': year},
    );
    return Board.fromJson(response.data);
  }

  /// Update a board (title and/or isDefault)
  Future<void> updateBoard(
    String id, {
    String? title,
    bool? isDefault,
  }) async {
    await _dio.put(
      ApiConstants.board(id),
      data: {
        if (title != null) 'title': title,
        if (isDefault != null) 'isDefault': isDefault,
      },
    );
  }

  /// Delete a board
  Future<void> deleteBoard(String id) async {
    await _dio.delete(ApiConstants.board(id));
  }

  /// Update a goal at a specific position
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
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (isCompleted != null) 'isCompleted': isCompleted,
      },
    );
  }

  /// Toggle goal completion
  Future<void> toggleGoal(String boardId, int position) async {
    await _dio.post(ApiConstants.toggleGoal(boardId, position));
  }
}
