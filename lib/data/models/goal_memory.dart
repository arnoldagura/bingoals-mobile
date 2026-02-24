class GoalMemory {
  final String id;
  final String goalId;
  final String imageUrl;
  final String label;
  final bool isBoardImage;
  final DateTime createdAt;

  const GoalMemory({
    required this.id,
    required this.goalId,
    required this.imageUrl,
    this.label = '',
    this.isBoardImage = false,
    required this.createdAt,
  });

  factory GoalMemory.fromJson(Map<String, dynamic> json) {
    return GoalMemory(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      imageUrl: json['imageUrl'] as String,
      label: json['label'] as String? ?? '',
      isBoardImage: json['isBoardImage'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'imageUrl': imageUrl,
      'label': label,
      'isBoardImage': isBoardImage,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  GoalMemory copyWith({
    String? id,
    String? goalId,
    String? imageUrl,
    String? label,
    bool? isBoardImage,
    DateTime? createdAt,
  }) {
    return GoalMemory(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      imageUrl: imageUrl ?? this.imageUrl,
      label: label ?? this.label,
      isBoardImage: isBoardImage ?? this.isBoardImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
