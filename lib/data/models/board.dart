import 'goal.dart';

class Board {
  final String id;
  final String title;
  final int year;
  final int gridSize;
  final String? category;
  final String? graceSquareTitle;
  final List<Goal> goals;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Board({
    required this.id,
    required this.title,
    required this.year,
    this.gridSize = 5,
    this.category,
    this.graceSquareTitle,
    required this.goals,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  int get goalCount => goals.length;

  int get completedCount =>
      goals.where((g) => g.isCompleted).length;

  int get progressPercent =>
      goalCount > 0 ? ((completedCount / goalCount) * 100).round() : 0;

  factory Board.empty({
    required String id,
    required String title,
    int? year,
    int gridSize = 5,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return Board(
      id: id,
      title: title,
      year: year ?? now.year,
      gridSize: gridSize,
      goals: List.generate(gridSize * gridSize, (i) => Goal.empty(i)),
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }

  Board copyWith({
    String? id,
    String? title,
    int? year,
    int? gridSize,
    String? category,
    String? graceSquareTitle,
    List<Goal>? goals,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Board(
      id: id ?? this.id,
      title: title ?? this.title,
      year: year ?? this.year,
      gridSize: gridSize ?? this.gridSize,
      category: category ?? this.category,
      graceSquareTitle: graceSquareTitle ?? this.graceSquareTitle,
      goals: goals ?? this.goals,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Board updateGoal(int position, Goal goal) {
    final newGoals = List<Goal>.from(goals);
    newGoals[position] = goal;
    return copyWith(goals: newGoals);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'year': year,
      'gridSize': gridSize,
      'category': category,
      'graceSquareTitle': graceSquareTitle,
      'goals': goals.map((g) => g.toJson()).toList(),
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'] as String,
      title: json['title'] as String,
      year: json['year'] as int,
      gridSize: json['gridSize'] as int? ?? 5,
      category: json['category'] as String?,
      graceSquareTitle: json['graceSquareTitle'] as String?,
      goals: _buildFullGrid(
        json['gridSize'] as int? ?? 5,
        (json['goals'] as List?)
                ?.map((g) => Goal.fromJson(g as Map<String, dynamic>))
                .toList() ??
            [],
      ),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static List<Goal> _buildFullGrid(int gridSize, List<Goal> sparse) {
    final total = gridSize * gridSize;
    final map = {for (var g in sparse) g.position: g};
    return List.generate(total, (i) => map[i] ?? Goal.empty(i));
  }
}

class BoardSummary {
  final String id;
  final String title;
  final int year;
  final int gridSize;
  final String? category;
  final int goalCount;
  final int completedCount;
  final bool isDefault;

  const BoardSummary({
    required this.id,
    required this.title,
    required this.year,
    this.gridSize = 5,
    this.category,
    required this.goalCount,
    required this.completedCount,
    this.isDefault = false,
  });

  int get progressPercent =>
      goalCount > 0 ? ((completedCount / goalCount) * 100).round() : 0;

  factory BoardSummary.fromBoard(Board board) {
    return BoardSummary(
      id: board.id,
      title: board.title,
      year: board.year,
      gridSize: board.gridSize,
      category: board.category,
      goalCount: board.goalCount,
      completedCount: board.completedCount,
      isDefault: board.isDefault,
    );
  }

  factory BoardSummary.fromJson(Map<String, dynamic> json) {
    return BoardSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      year: json['year'] as int,
      gridSize: json['gridSize'] as int? ?? 5,
      category: json['category'] as String?,
      goalCount: json['goalCount'] as int? ?? 0,
      completedCount: json['completedCount'] as int? ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
