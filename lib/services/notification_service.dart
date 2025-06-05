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

      if (response == null) {
        throw Exception('Failed to fetch notifications');
      }

      return (response as List).map((json) => UserNotification.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch user notifications: $e');
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
