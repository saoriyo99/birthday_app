import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post.dart';
class PostService {
  final SupabaseClient supabase;
  final String? currentUserId;

  PostService(this.supabase, {this.currentUserId});

  Future<List<Post>> fetchPosts({
    String? targetFriend,
    String? targetGroup,
    DateTime? beforeCreatedAt,
    int fetchLimit = 20,
  }) async {
    try {
      Map<String, dynamic> params = {
        'fetch_limit': fetchLimit,
      };

      if (targetFriend != null) {
        debugPrint('fetchPosts called for friend: $targetFriend');
        params['target_friend'] = targetFriend;
      }
      if (targetGroup != null) {
        debugPrint('fetchPost targetGroup: ${targetGroup!}');
        params['target_group'] = targetGroup;
        debugPrint('fetchPost params[targetGroup]: ${params['target_group']!}');
      }

      if (beforeCreatedAt != null) {
        params['before_created_at'] = beforeCreatedAt.toIso8601String();
      }
      
      debugPrint('fetchPost params: ${params!}');

      final data = await supabase
      .schema('social')
      .rpc('get_posts', params: params);

      debugPrint('fetchPost final data: ${data!}');

      // handle null response safely
      if (data == null) {
        return [];
      }

      final List<Map<String, dynamic>> postMaps = (data as List<dynamic>).cast<Map<String, dynamic>>();
      return Future.wait(postMaps.map((map) => Post.fromMapAsync(map)).toList());
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      rethrow;
    }
  }

  Future<List<Post>> fetchPostsForGroup(String groupId) async {
    debugPrint('Inside post_service.fetchPostsForGroup groupID: ${groupId}');
    return fetchPosts(targetGroup: groupId);
  }

  Future<List<Post>> fetchPostsForFriend(String friendId) async {
    debugPrint('fetchPostsForFriend called with friendId: $friendId');
    return fetchPosts(targetFriend: friendId);
  }

}
