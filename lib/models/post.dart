import 'package:uuid/uuid.dart';

class Post {
  final String id;
  final String userId; // Changed from creatorId to userId
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final String userFirstName;
  final String userLastName;

  Post({
    required this.id,
    required this.userId, // Changed from creatorId to userId
    required this.text,
    this.imageUrl,
    required this.createdAt,
    required this.userFirstName,
    required this.userLastName,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['post_id'] as String,
      userId: map['author_id'] as String,
      text: map['text'] as String,
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      userFirstName: map['author_first_name'] as String,
      userLastName: map['author_last_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId, // Changed from creator_id to user_id
      'text': text,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'first_name': userFirstName,
      'last_name': userLastName,
    };
  }
}
