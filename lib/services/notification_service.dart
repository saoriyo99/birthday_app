import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/models/notification.dart';

/// Service for handling notification-related operations.
class NotificationService {
  final SupabaseClient _supabaseClient;

  NotificationService(this._supabaseClient);

  /// Fetches the list of notifications for the current user.
  Future<List<UserNotification>> fetchUserNotifications() async {
    final currentUser = _supabaseClient.auth.currentUser;
    if (currentUser == null) {
      return [];
    }
    try {
      final response = await _supabaseClient
          .schema('social')
          .from('notifications')
          .select()
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      return (response as List).map((json) => UserNotification.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user notifications: $e');
    }
  }

  /// Inserts a new notification into the database.
  Future<void> insertNotification({
    required String userId,
    required String type,
    required String content,
    required String sourceId,
  }) async {
    try {
      await _supabaseClient.schema('social').from('notifications').insert({
        'user_id': userId,
        'type': type,
        'content': content,
        'source_id': sourceId,
        'is_read': false, // New notifications are unread by default
        'action_required': false, // Default to false, can be extended later
      });
    } catch (e) {
      throw Exception('Failed to insert notification: $e');
    }
  }

  /// Marks a notification as read by its ID.
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _supabaseClient
          .schema('social')
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }
}
