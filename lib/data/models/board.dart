import 'goal.dart';

/// Represents a bingo board with 25 goals
class Board {
  final String id;
  final String title;
  final int year;
  final List<Goal> goals;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Board({
    required this.id,
    required this.title,
    required this.year,
    required this.goals,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Number of goals that have content
  int get goalCount => goals.where((g) => !g.isEmpty).length;

  /// Number of completed goals
  int get completedCount => goals.where((g) => g.isCompleted).length;

  /// Completion percentage
  int get progressPercent =>
      goalCount > 0 ? ((completedCount / goalCount) * 100).round() : 0;

  /// Create a new empty board
  factory Board.empty({
    required String id,
    required String title,
    int? year,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return Board(
      id: id,
      title: title,
      year: year ?? now.year,
      goals: List.generate(25, (i) => Goal.empty(i)),
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }

  Board copyWith({
    String? id,
    String? title,
    int? year,
    List<Goal>? goals,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Board(
      id: id ?? this.id,
      title: title ?? this.title,
      year: year ?? this.year,
      goals: goals ?? this.goals,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Update a goal at a specific position
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
      goals: (json['goals'] as List)
          .map((g) => Goal.fromJson(g as Map<String, dynamic>))
          .toList(),
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Summary of a board for dashboard display
class BoardSummary {
  final String id;
  final String title;
  final int year;
  final int goalCount;
  final int completedCount;
  final bool isDefault;

  const BoardSummary({
    required this.id,
    required this.title,
    required this.year,
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
      goalCount: json['goalCount'] as int? ?? 0,
      completedCount: json['completedCount'] as int? ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
