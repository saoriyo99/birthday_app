import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/services/notification_service.dart';

class WishService {
  final SupabaseClient _supabaseClient;
  final NotificationService _notificationService;

  WishService(this._supabaseClient)
      : _notificationService = NotificationService(_supabaseClient);

  /// Inserts a new wish into the database and sends a notification to the recipient.
  Future<void> insertWishAndNotification({
    required String senderId,
    required String recipientId,
    required String message,
  }) async {
    try {
      // 1. Insert the wish into social.wishes
      final response = await _supabaseClient.from('social.wishes').insert({
        'sender_id': senderId,
        'recipient_id': recipientId,
        'message': message,
        'type': 'birthday_wish', // Or a more specific type if needed
        'loved': false,
        'is_read': false,
      }).select('id').single(); // Select the ID of the newly inserted wish

      final String insertedWishId = response['id'];

      // 2. Insert the notification for wish_received
      await _notificationService.insertNotification(
        userId: recipientId,
        type: 'wish_received',
        content: 'Someone wished you a happy birthday!', // Generic content, can be customized
        sourceId: senderId,
        wishId: insertedWishId, // Pass the actual wishId
      );
    } catch (e) {
      throw Exception('Failed to send wish and notification: $e');
    }
  }
}
