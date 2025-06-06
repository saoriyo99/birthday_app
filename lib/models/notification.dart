class UserNotification {
  final String id;
  final DateTime createdAt;
  final String type;
  final String content;
  final bool isRead;
  final String userId;
  final String sourceId;
  final bool actionRequired;
  final String? wishId; // Made nullable

  UserNotification({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.content,
    required this.isRead,
    required this.userId,
    required this.sourceId,
    required this.actionRequired,
    this.wishId, // No longer required
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) {
    return UserNotification(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      type: json['type'],
      content: json['content'],
      isRead: json['is_read'],
      userId: json['user_id'],
      sourceId: json['source_id'],
      actionRequired: json['action_required'] ?? false, // Default to false if not present
      wishId: json['wish_id'], // Corrected to snake_case and no default empty string
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'type': type,
      'content': content,
      'is_read': isRead,
      'user_id': userId,
      'source_id': sourceId,
      'action_required': actionRequired,
      'wish_id': wishId, // Corrected to snake_case
    };
  }
}
