import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:flutter/foundation.dart'; // For debugPrint

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
    return Post._internal(
      id: map['post_id'] as String,
      userId: map['author_id'] as String,
      text: map['text'] as String,
      imageUrl: map['image_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      userFirstName: map['author_first_name'] as String,
      userLastName: map['author_last_name'] as String,
    );
  }

  // Private constructor for internal use by fromMapAsync
  Post._internal({
    required this.id,
    required this.userId,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    required this.userFirstName,
    required this.userLastName,
  });

  static Future<Post> fromMapAsync(Map<String, dynamic> map) async {
    String? finalImageUrl;
    final String? rawImageUrl = map['image_url'] as String?;

    if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
      try {
        final Uri uri = Uri.parse(rawImageUrl);
        // Check if it's a Supabase public URL and specifically for 'post-images' bucket
        if (uri.pathSegments.length >= 6 && uri.pathSegments[4] == 'post-images') {
          final String pathInBucket = uri.pathSegments.sublist(5).join('/');
          finalImageUrl = await Supabase.instance.client.storage
              .from('post-images')
              .createSignedUrl(pathInBucket, 60); // Generate signed URL for 60 seconds
          debugPrint('Successfully created signed URL for $pathInBucket: $finalImageUrl');
        } else {
          // If it's not a Supabase public URL, assume it's already a direct URL or log a warning
          finalImageUrl = rawImageUrl; // Use as is
          debugPrint('Warning: Image URL does not match expected Supabase public URL format, using as is: $rawImageUrl');
        }
      } catch (e, stackTrace) {
        debugPrint('Error processing image URL $rawImageUrl: $e\n$stackTrace');
        finalImageUrl = null; // Set to null if any error occurs during processing
      }
    }

    return Post._internal(
      id: map['post_id'] as String,
      userId: map['author_id'] as String,
      text: map['text'] as String,
      imageUrl: finalImageUrl,
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
