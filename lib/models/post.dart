class Post {
  final String id;
  final String? text; // Changed from content, made nullable
  final String? imageUrl; // New field for image URL
  final String userId; // Changed from author
  final DateTime timestamp;
  final String groupId; // To link posts to groups

  Post({
    required this.id,
    this.text, // Made optional
    this.imageUrl, // Made optional
    required this.userId, // Changed from author
    required this.timestamp,
    required this.groupId,
  });

  // Factory constructor to create a Post from a map (e.g., from JSON)
  factory Post.fromMap(Map<String, dynamic> data) {
    return Post(
      id: data['id'] as String,
      text: data['text'] as String?, // Changed from content
      imageUrl: data['image_url'] as String?, // New field
      userId: data['user_id'] as String, // Changed from author
      timestamp: DateTime.parse(data['created_at'] as String), // Changed from timestamp
      groupId: data['group_id'] as String, // Changed from groupId
    );
  }

  // Method to convert a Post to a map (e.g., for saving to database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text, // Changed from content
      'image_url': imageUrl, // New field
      'user_id': userId, // Changed from author
      'created_at': timestamp.toIso8601String(), // Changed from timestamp
      'group_id': groupId, // Changed from groupId
    };
  }
}
