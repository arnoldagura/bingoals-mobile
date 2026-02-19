import 'user.dart';

class Comment {
  final String id;
  final String goalId;
  final String userId;
  final String text;
  final User? user;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.text,
    this.user,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      userId: json['userId'] as String,
      text: json['text'] as String,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
