class BoardInvite {
  final String id;
  final String boardId;
  final String inviterId;
  final String inviteCode;
  final DateTime? expiresAt;
  final int maxUses;
  final int usedCount;
  final DateTime createdAt;

  const BoardInvite({
    required this.id,
    required this.boardId,
    required this.inviterId,
    required this.inviteCode,
    this.expiresAt,
    this.maxUses = 0,
    this.usedCount = 0,
    required this.createdAt,
  });

  factory BoardInvite.fromJson(Map<String, dynamic> json) {
    return BoardInvite(
      id: json['id'] as String,
      boardId: json['boardId'] as String,
      inviterId: json['inviterId'] as String,
      inviteCode: json['inviteCode'] as String,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      maxUses: json['maxUses'] as int? ?? 0,
      usedCount: json['usedCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
