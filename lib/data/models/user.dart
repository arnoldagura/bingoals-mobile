class User {
  final String id;
  final String email;
  final String name;
  final int dailyStreak;
  final int totalGems;
  final String level;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.dailyStreak = 0,
    this.totalGems = 0,
    this.level = 'bronze',
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      dailyStreak: json['dailyStreak'] as int? ?? 0,
      totalGems: json['totalGems'] as int? ?? 0,
      level: json['level'] as String? ?? 'bronze',
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'dailyStreak': dailyStreak,
      'totalGems': totalGems,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
