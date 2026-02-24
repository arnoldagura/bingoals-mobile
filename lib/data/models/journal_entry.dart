class JournalEntry {
  final String id;
  final String type; // goal_completed, milestone_reached, reflection_added
  final String goalTitle;
  final String boardTitle;
  final String boardId;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;

  const JournalEntry({
    required this.id,
    required this.type,
    required this.goalTitle,
    required this.boardTitle,
    required this.boardId,
    required this.content,
    required this.imageUrl,
    required this.timestamp,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) {
    return JournalEntry(
      id: json['id'] as String,
      type: json['type'] as String,
      goalTitle: json['goalTitle'] as String? ?? '',
      boardTitle: json['boardTitle'] as String? ?? '',
      boardId: json['boardId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
