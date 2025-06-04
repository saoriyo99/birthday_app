import 'package:supabase_flutter/supabase_flutter.dart';

class FriendService {
  final SupabaseClient _supabaseClient;

  FriendService(this._supabaseClient);

  Future<List<Map<String, dynamic>>> fetchUserFriends() async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return [];
    }
    try {
      final friendsResponse = await _supabaseClient
          .schema('social')
          .rpc('get_user_friends', params: {'target_user_id': currentUser.id});

      if (friendsResponse == null) {
        throw Exception('Failed to fetch friends');
      }

      return friendsResponse.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch user friends: $e');
    }
  }
}
