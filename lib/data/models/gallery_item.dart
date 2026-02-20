class GalleryItem {
  final String milestoneId;
  final String title;
  final String? imageUrl;
  final bool isComplete;
  final String goalTitle;
  final String boardTitle;
  final String boardId;
  final int position;
  final DateTime createdAt;

  const GalleryItem({
    required this.milestoneId,
    required this.title,
    this.imageUrl,
    required this.isComplete,
    required this.goalTitle,
    required this.boardTitle,
    required this.boardId,
    required this.position,
    required this.createdAt,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      milestoneId: json['milestoneId'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
      isComplete: json['isComplete'] as bool? ?? false,
      goalTitle: json['goalTitle'] as String? ?? '',
      boardTitle: json['boardTitle'] as String? ?? '',
      boardId: json['boardId'] as String,
      position: json['position'] as int,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
