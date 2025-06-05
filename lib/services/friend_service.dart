import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/models/friend.dart';
import 'package:birthday_app/models/user_profile.dart';
import 'dart:developer'; // For log, a better alternative to print/debugPrint for Flutter

/// Service for handling friend-related operations.
class FriendService {
  final SupabaseClient _supabaseClient;

  FriendService(this._supabaseClient);

  /// Fetches the list of friends for the current user.
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

  /// Fetches a single user profile by ID.
  Future<UserProfile?> fetchUserProfileById(String userId) async {
    try {
      final response = await _supabaseClient
          .schema('social')
          .from('users')
          .select()
          .eq('id', userId)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserProfile.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      log('Error fetching user profile by ID: $e'); // Use log for better debugging in Flutter
      return null;
    }
  }
}
