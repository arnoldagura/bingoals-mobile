import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../models/board.dart';
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
  }) async {
    final response = await _dio.post(
      ApiConstants.boards,
      data: {
        'title': title,
        'year': ?year,
        'gridSize': gridSize,
        'category': ?category,
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
    required int percentage,
  }) async {
    final response = await _dio.post(
      ApiConstants.miniGoals(boardId, position),
      data: {'title': title, 'percentage': percentage},
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
  }) async {
    final response = await _dio.put(
      ApiConstants.miniGoal(boardId, position, miniGoalId),
      data: {
        'title': ?title,
        'percentage': ?percentage,
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
}
