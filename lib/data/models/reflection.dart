class Reflection {
  final String id;
  final String goalId;
  final String? obstacles;
  final String? victories;
  final String? notes;
  final String? reflectionPrompt;
  final String? reflectionAnswer;

  const Reflection({
    required this.id,
    required this.goalId,
    this.obstacles,
    this.victories,
    this.notes,
    this.reflectionPrompt,
    this.reflectionAnswer,
  });

  Reflection copyWith({
    String? id,
    String? goalId,
    String? obstacles,
    String? victories,
    String? notes,
    String? reflectionPrompt,
    String? reflectionAnswer,
  }) {
    return Reflection(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      obstacles: obstacles ?? this.obstacles,
      victories: victories ?? this.victories,
      notes: notes ?? this.notes,
      reflectionPrompt: reflectionPrompt ?? this.reflectionPrompt,
      reflectionAnswer: reflectionAnswer ?? this.reflectionAnswer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'obstacles': obstacles,
      'victories': victories,
      'notes': notes,
      'reflectionPrompt': reflectionPrompt,
      'reflectionAnswer': reflectionAnswer,
    };
  }

  factory Reflection.fromJson(Map<String, dynamic> json) {
    return Reflection(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      obstacles: json['obstacles'] as String?,
      victories: json['victories'] as String?,
      notes: json['notes'] as String?,
      reflectionPrompt: json['reflectionPrompt'] as String?,
      reflectionAnswer: json['reflectionAnswer'] as String?,
    );
  }
}
