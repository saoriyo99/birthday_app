import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/models/post.dart';

/// Service for handling post-related operations.
class PostService {
  final SupabaseClient _supabaseClient;

  PostService(this._supabaseClient);

  /// Fetches posts for the current user, optionally filtered by friend, group, or date.
  Future<List<Post>> fetchPosts({
    String? targetFriend,
    String? targetGroup,
    DateTime? beforeCreatedAt,
    int fetchLimit = 20,
  }) async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return [];
    }
    try {
      final Map<String, dynamic> params = {
        'fetch_limit': fetchLimit,
      };

      if (targetFriend != null) {
        params['target_friend'] = targetFriend;
      }
      if (targetGroup != null) {
        params['target_group'] = targetGroup;
      }
      if (beforeCreatedAt != null) {
        params['before_created_at'] = beforeCreatedAt.toIso8601String();
      }

      final data = await _supabaseClient
          .schema('social')
          .rpc('get_posts', params: params);

      if (data == null) {
        return [];
      }

      final List<Map<String, dynamic>> postMaps =
          (data as List<dynamic>).cast<Map<String, dynamic>>();
      // Use Post.fromMapAsync if required by the model, otherwise use Post.fromMap
      return Future.wait(postMaps.map((map) => Post.fromMapAsync(map)).toList());
    } catch (e) {
      throw Exception('Failed to fetch posts: $e');
    }
  }

  /// Fetches posts for a specific group.
  Future<List<Post>> fetchPostsForGroup(String groupId) async {
    return fetchPosts(targetGroup: groupId);
  }

  /// Fetches posts for a specific friend.
  Future<List<Post>> fetchPostsForFriend(String friendId) async {
    return fetchPosts(targetFriend: friendId);
  }
}
