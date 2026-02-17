import 'goal.dart';

/// Lightweight member info included in board responses
class MemberInfo {
  final String id;
  final String name;
  final String displayName;
  final String avatarUrl;
  final String role; // owner, member

  const MemberInfo({
    required this.id,
    this.name = '',
    this.displayName = '',
    this.avatarUrl = '',
    this.role = 'member',
  });

  bool get isOwner => role == 'owner';

  String get displayLabel =>
      displayName.isNotEmpty ? displayName : (name.isNotEmpty ? name : 'User');

  String get initials {
    final label = displayLabel;
    final parts = label.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return label.isNotEmpty ? label[0].toUpperCase() : '?';
  }

  factory MemberInfo.fromJson(Map<String, dynamic> json) {
    // GetBoard returns BoardMember with nested "user" object;
    // GetBoards summary returns flat MemberInfo.
    final user = json['user'] as Map<String, dynamic>?;
    return MemberInfo(
      id: json['userId'] as String? ?? json['id'] as String,
      name: user?['name'] as String? ?? json['name'] as String? ?? '',
      displayName: user?['displayName'] as String? ?? json['displayName'] as String? ?? '',
      avatarUrl: user?['avatarUrl'] as String? ?? json['avatarUrl'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
    );
  }
}

class Board {
  final String id;
  final String title;
  final int year;
  final int gridSize;
  final String? category;
  final String boardType; // personal, shared
  final int maxMembers;
  final String? graceSquareTitle;
  final List<Goal> goals;
  final List<MemberInfo> members;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Board({
    required this.id,
    required this.title,
    required this.year,
    this.gridSize = 5,
    this.category,
    this.boardType = 'personal',
    this.maxMembers = 5,
    this.graceSquareTitle,
    required this.goals,
    this.members = const [],
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isShared => boardType == 'shared';

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
    String? boardType,
    int? maxMembers,
    String? graceSquareTitle,
    List<Goal>? goals,
    List<MemberInfo>? members,
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
      boardType: boardType ?? this.boardType,
      maxMembers: maxMembers ?? this.maxMembers,
      graceSquareTitle: graceSquareTitle ?? this.graceSquareTitle,
      goals: goals ?? this.goals,
      members: members ?? this.members,
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
      'boardType': boardType,
      'maxMembers': maxMembers,
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
      boardType: json['boardType'] as String? ?? 'personal',
      maxMembers: json['maxMembers'] as int? ?? 5,
      graceSquareTitle: json['graceSquareTitle'] as String?,
      goals: _buildFullGrid(
        json['gridSize'] as int? ?? 5,
        (json['goals'] as List?)
                ?.map((g) => Goal.fromJson(g as Map<String, dynamic>))
                .toList() ??
            [],
      ),
      members: (json['members'] as List?)
              ?.map((m) => MemberInfo.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
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
  final String boardType;
  final int maxMembers;
  final int goalCount;
  final int completedCount;
  final int memberCount;
  final List<MemberInfo> members;
  final bool isDefault;

  const BoardSummary({
    required this.id,
    required this.title,
    required this.year,
    this.gridSize = 5,
    this.category,
    this.boardType = 'personal',
    this.maxMembers = 5,
    required this.goalCount,
    required this.completedCount,
    this.memberCount = 0,
    this.members = const [],
    this.isDefault = false,
  });

  bool get isShared => boardType == 'shared';

  int get progressPercent =>
      goalCount > 0 ? ((completedCount / goalCount) * 100).round() : 0;

  factory BoardSummary.fromBoard(Board board) {
    return BoardSummary(
      id: board.id,
      title: board.title,
      year: board.year,
      gridSize: board.gridSize,
      category: board.category,
      boardType: board.boardType,
      maxMembers: board.maxMembers,
      goalCount: board.goalCount,
      completedCount: board.completedCount,
      memberCount: board.members.length,
      members: board.members,
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
      boardType: json['boardType'] as String? ?? 'personal',
      maxMembers: json['maxMembers'] as int? ?? 5,
      goalCount: json['goalCount'] as int? ?? 0,
      completedCount: json['completedCount'] as int? ?? 0,
      memberCount: json['memberCount'] as int? ?? 0,
      members: (json['members'] as List?)
              ?.map((m) => MemberInfo.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }
}
