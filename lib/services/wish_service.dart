import 'package:flutter/material.dart'; // Import for debugPrint
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
    String? senderFirstName, // New parameter
    String? senderLastName, // New parameter
  }) async {
    try {
      debugPrint('WishService: Attempting to insert wish...');
      debugPrint('Sender ID: $senderId, Recipient ID: $recipientId, Message: $message');

      // 1. Insert the wish into social.wishes
      final response = await _supabaseClient.schema('social').from('wishes').insert({
        'sender_id': senderId,
        'recipient_id': recipientId,
        'message': message,
        'type': 'birthday_wish', // Or a more specific type if needed
        'loved': false,
        'is_read': false,
      }).select('id').single(); // Select the ID of the newly inserted wish

      final String insertedWishId = response['id'];
      debugPrint('WishService: Wish inserted successfully with ID: $insertedWishId');

      // Construct notification content with sender's name if available
      String notificationContent;
      if (senderFirstName != null && senderLastName != null) {
        notificationContent = '$senderFirstName $senderLastName wished you a happy birthday!';
      } else if (senderFirstName != null) {
        notificationContent = '$senderFirstName wished you a happy birthday!';
      } else {
        notificationContent = 'Someone wished you a happy birthday!';
      }

      // 2. Insert the notification for wish_received
      debugPrint('WishService: Attempting to insert notification...');
      await _notificationService.insertNotification(
        userId: recipientId,
        type: 'wish_received',
        content: notificationContent, // Use customized content
        sourceId: senderId,
        wishId: insertedWishId, // Pass the actual wishId
      );
      debugPrint('WishService: Notification inserted successfully.');
    } catch (e) {
      debugPrint('WishService Error: Failed to send wish and notification: $e');
      throw Exception('Failed to send wish and notification: $e');
    }
  }
}
