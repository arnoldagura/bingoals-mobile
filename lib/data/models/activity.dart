import 'user.dart';

class Activity {
  final String id;
  final String boardId;
  final String userId;
  final String actionType; // goal_completed, goal_assigned, member_joined, member_left, reaction
  final String? targetId;
  final String? metadata; // JSON string
  final User? user;
  final DateTime createdAt;

  const Activity({
    required this.id,
    required this.boardId,
    required this.userId,
    required this.actionType,
    this.targetId,
    this.metadata,
    this.user,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      boardId: json['boardId'] as String,
      userId: json['userId'] as String,
      actionType: json['actionType'] as String,
      targetId: json['targetId'] as String?,
      metadata: json['metadata'] as String?,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ActivityPage {
  final List<Activity> activities;
  final int total;
  final int page;
  final int limit;

  const ActivityPage({
    required this.activities,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory ActivityPage.fromJson(Map<String, dynamic> json) {
    return ActivityPage(
      activities: (json['activities'] as List?)
              ?.map((a) => Activity.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }
}
