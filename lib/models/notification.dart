import 'package:uuid/uuid.dart';

class UserNotification {
  final String id;
  final DateTime createdAt;
  final String type;
  final String content;
  final bool isRead;
  final String userId;
  final String sourceId;
  final bool actionRequired;

  UserNotification({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.content,
    required this.isRead,
    required this.userId,
    required this.sourceId,
    required this.actionRequired,
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
      actionRequired: json['action_required'],
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
    };
  }
}
