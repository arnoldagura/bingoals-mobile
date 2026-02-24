class MiniGoal {
  final String id;
  final String goalId;
  final String title;
  final int? percentage;
  final bool isComplete;
  final String? imageUrl;

  const MiniGoal({
    required this.id,
    required this.goalId,
    required this.title,
    this.percentage,
    this.isComplete = false,
    this.imageUrl,
  });

  MiniGoal copyWith({
    String? id,
    String? goalId,
    String? title,
    int? percentage,
    bool? isComplete,
    String? imageUrl,
  }) {
    return MiniGoal(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      percentage: percentage ?? this.percentage,
      isComplete: isComplete ?? this.isComplete,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'title': title,
      if (percentage != null) 'percentage': percentage,
      'isComplete': isComplete,
      'imageUrl': imageUrl,
    };
  }

  factory MiniGoal.fromJson(Map<String, dynamic> json) {
    return MiniGoal(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      title: json['title'] as String,
      percentage: json['percentage'] as int?,
      isComplete: json['isComplete'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
