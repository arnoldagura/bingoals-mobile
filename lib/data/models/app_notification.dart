class AppNotification {
  final String id;
  final String userId;
  final String type; // board_invite, goal_completed, reaction_received, member_joined
  final String title;
  final String body;
  final bool read;
  final String? metadata; // JSON string with navigation context
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body = '',
    this.read = false,
    this.metadata,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      metadata: json['metadata'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class NotificationPage {
  final List<AppNotification> notifications;
  final int total;
  final int unread;
  final int page;
  final int limit;

  const NotificationPage({
    required this.notifications,
    required this.total,
    required this.unread,
    required this.page,
    required this.limit,
  });

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    return NotificationPage(
      notifications: (json['notifications'] as List?)
              ?.map((n) =>
                  AppNotification.fromJson(n as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      unread: json['unread'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 20,
    );
  }
}
