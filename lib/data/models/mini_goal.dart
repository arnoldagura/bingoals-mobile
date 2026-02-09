class MiniGoal {
  final String id;
  final String goalId;
  final String title;
  final int percentage;
  final bool isComplete;

  const MiniGoal({
    required this.id,
    required this.goalId,
    required this.title,
    required this.percentage,
    this.isComplete = false,
  });

  MiniGoal copyWith({
    String? id,
    String? goalId,
    String? title,
    int? percentage,
    bool? isComplete,
  }) {
    return MiniGoal(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      percentage: percentage ?? this.percentage,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'title': title,
      'percentage': percentage,
      'isComplete': isComplete,
    };
  }

  factory MiniGoal.fromJson(Map<String, dynamic> json) {
    return MiniGoal(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      title: json['title'] as String,
      percentage: json['percentage'] as int,
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }
}
