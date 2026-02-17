import 'user.dart';

class Reaction {
  final String id;
  final String goalId;
  final String userId;
  final String type; // fire, heart, clap, star
  final User? user;
  final DateTime createdAt;

  const Reaction({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.type,
    this.user,
    required this.createdAt,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
