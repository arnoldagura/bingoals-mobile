class User {
  final String id;
  final String email;
  final String name;
  final String displayName;
  final String avatarUrl;
  final String bio;
  final int dailyStreak;
  final int totalGems;
  final String level;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.displayName = '',
    this.avatarUrl = '',
    this.bio = '',
    this.dailyStreak = 0,
    this.totalGems = 0,
    this.level = 'bronze',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Display name to show in UI (falls back to name, then email)
  String get displayLabel =>
      displayName.isNotEmpty ? displayName : (name.isNotEmpty ? name : email);

  /// Initials for avatar placeholder
  String get initials {
    final label = displayLabel;
    final parts = label.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return label.isNotEmpty ? label[0].toUpperCase() : '?';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
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
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'dailyStreak': dailyStreak,
      'totalGems': totalGems,
      'level': level,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? name,
    String? displayName,
    String? avatarUrl,
    String? bio,
    int? dailyStreak,
    int? totalGems,
    String? level,
  }) {
    return User(
      id: id,
      email: email,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      dailyStreak: dailyStreak ?? this.dailyStreak,
      totalGems: totalGems ?? this.totalGems,
      level: level ?? this.level,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
