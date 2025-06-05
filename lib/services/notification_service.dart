import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification.dart';

class NotificationService {
  final SupabaseClient _supabaseClient;

  NotificationService(this._supabaseClient);

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
