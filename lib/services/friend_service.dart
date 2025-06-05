import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friend.dart'; // Import the new Friend model

class FriendService {
  final SupabaseClient _supabaseClient;

  FriendService(this._supabaseClient);

  Future<List<Friend>> fetchUserFriends() async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return [];
    }
    try {
      final friendsResponse = await _supabaseClient
          .schema('social')
          .rpc('get_user_friends', params: {'target_user_id': currentUser.id});

      if (friendsResponse == null) {
        return [];
      }

      return (friendsResponse as List<dynamic>)
          .map((map) => Friend.fromMap(map as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user friends: $e');
    }
  }
}
