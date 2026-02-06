/// Represents a single goal in a bingo board
class Goal {
  final String id;
  final String? title;
  final String? description;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? imageUrl;
  final int position; // 0-24 for 5x5 grid

  const Goal({
    required this.id,
    this.title,
    this.description,
    this.isCompleted = false,
    this.completedAt,
    this.imageUrl,
    required this.position,
  });

  bool get isEmpty => title == null || title!.isEmpty;

  Goal copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? completedAt,
    String? imageUrl,
    int? position,
  }) {
    return Goal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      position: position ?? this.position,
    );
  }

  /// Create an empty goal at a position
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
      'isCompleted': isCompleted,
      'completedAt': completedAt?.toIso8601String(),
      'imageUrl': imageUrl,
      'position': position,
    };
  }

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String?,
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
      position: json['position'] as int,
    );
  }
}
