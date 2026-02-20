import 'mini_goal.dart';
import 'reflection.dart';

enum GoalStatus { notStarted, inProgress, completed }

GoalStatus goalStatusFromString(String? value) {
  switch (value) {
    case 'in_progress':
      return GoalStatus.inProgress;
    case 'completed':
      return GoalStatus.completed;
    default:
      return GoalStatus.notStarted;
  }
}

String goalStatusToString(GoalStatus status) {
  switch (status) {
    case GoalStatus.inProgress:
      return 'in_progress';
    case GoalStatus.completed:
      return 'completed';
    case GoalStatus.notStarted:
      return 'not_started';
  }
}

class Goal {
  final String id;
  final String? title;
  final String? description;
  final GoalStatus status;
  final bool isCompleted;
  final bool isGraceSquare;
  final int progress;
  final DateTime? completedAt;
  final String? icon;
  final String? imageUrl;
  final String? mood;
  final String? assignedTo;
  final String? completedBy;
  final int position;
  final List<MiniGoal> miniGoals;
  final Reflection? reflection;
  final int completedByCount; // How many members completed this (shared boards only)

  const Goal({
    required this.id,
    this.title,
    this.description,
    this.status = GoalStatus.notStarted,
    this.isCompleted = false,
    this.isGraceSquare = false,
    this.progress = 0,
    this.completedAt,
    this.icon,
    this.imageUrl,
    this.mood,
    this.assignedTo,
    this.completedBy,
    required this.position,
    this.miniGoals = const [],
    this.reflection,
    this.completedByCount = 0,
  });

  bool get isEmpty => title == null || title!.isEmpty;

  bool get isInProgress => status == GoalStatus.inProgress;

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    GoalStatus? status,
    bool? isCompleted,
    bool? isGraceSquare,
    int? progress,
    DateTime? completedAt,
    String? icon,
    String? imageUrl,
    String? mood,
    String? assignedTo,
    String? completedBy,
    int? position,
    List<MiniGoal>? miniGoals,
    Reflection? reflection,
    int? completedByCount,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      isGraceSquare: isGraceSquare ?? this.isGraceSquare,
      progress: progress ?? this.progress,
      completedAt: completedAt ?? this.completedAt,
      icon: icon ?? this.icon,
      imageUrl: imageUrl ?? this.imageUrl,
      mood: mood ?? this.mood,
      assignedTo: assignedTo ?? this.assignedTo,
      completedBy: completedBy ?? this.completedBy,
      position: position ?? this.position,
      miniGoals: miniGoals ?? this.miniGoals,
      reflection: reflection ?? this.reflection,
      completedByCount: completedByCount ?? this.completedByCount,
    );
  }

  factory Goal.empty(int position) {
    return Goal(
      id: 'goal_$position',
      position: position,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': goalStatusToString(status),
      'isCompleted': isCompleted,
      'isGraceSquare': isGraceSquare,
      'progress': progress,
      'completedAt': completedAt?.toIso8601String(),
      'icon': icon,
      'imageUrl': imageUrl,
      'mood': mood,
      'assignedTo': assignedTo,
      'completedBy': completedBy,
      'position': position,
      'miniGoals': miniGoals.map((mg) => mg.toJson()).toList(),
      'reflection': reflection?.toJson(),
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      status: goalStatusFromString(json['status'] as String?),
      isCompleted: json['isCompleted'] as bool? ?? false,
      isGraceSquare: json['isGraceSquare'] as bool? ?? false,
      progress: json['progress'] as int? ?? 0,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      icon: json['icon'] as String?,
      imageUrl: json['imageUrl'] as String?,
      mood: json['mood'] as String?,
      assignedTo: json['assignedTo'] as String?,
      completedBy: json['completedBy'] as String?,
      position: json['position'] as int,
      miniGoals: json['miniGoals'] != null
          ? (json['miniGoals'] as List)
              .map((mg) => MiniGoal.fromJson(mg as Map<String, dynamic>))
              .toList()
          : [],
      reflection: json['reflection'] != null
          ? Reflection.fromJson(json['reflection'] as Map<String, dynamic>)
          : null,
      completedByCount: json['completedByCount'] as int? ?? 0,
    );
  }
}
