import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/services/notification_service.dart';
import 'package:birthday_app/models/user_profile.dart'; // Import UserProfile
import 'package:birthday_app/services/friend_service.dart'; // Import FriendService

class WishScreen extends StatefulWidget {
  final String? wishId;

  const WishScreen({Key? key, this.wishId}) : super(key: key);

  @override
  _WishScreenState createState() => _WishScreenState();
}

class _WishScreenState extends State<WishScreen> with SingleTickerProviderStateMixin {
  late Future<dynamic> _wishFuture;
  late NotificationService _notificationService;
  late FriendService _friendService; // Declare FriendService
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(Supabase.instance.client);
    _friendService = FriendService(Supabase.instance.client); // Initialize FriendService
    _wishFuture = loadWish();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  Future<dynamic> loadWish() async {
    if (widget.wishId == null) {
      throw Exception('Wish ID is null. Cannot load wish.');
    }
    final response = await Supabase.instance.client
        .schema('social')
        .from('wishes')
        .select('id, sender_id, recipient_id, message, type, loved, is_read, created_at')
        .eq('id', widget.wishId!)
        .single();

    debugPrint('Wish loaded: ${response['id']}, Loved status: ${response['loved']}');
    return response;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _wishFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Something went wrong 🥲',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Text(
                'Wish not found.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          );
        }

        final wish = snapshot.data;
        final isLoved = wish['loved'] as bool;
        final message = wish['message'] as String;
        final senderId = wish['sender_id'] as String;

        // Fetch sender's profile
        return FutureBuilder<UserProfile?>(
          future: _friendService.fetchUserProfileById(senderId),
          builder: (context, senderProfileSnapshot) {
            if (senderProfileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            final senderProfile = senderProfileSnapshot.data;
            final senderFullName = senderProfile != null
                ? '${senderProfile.firstName} ${senderProfile.lastName}'
                : 'them'; // Fallback to 'them' if sender profile not found

            return Scaffold(
              extendBodyBehindAppBar: true,
              backgroundColor: const Color(0xFFF7F7F9),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.black87),
              ),
              body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GlassCard(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              "A special wish for you",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: Text(
                                message,
                                key: ValueKey(message),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 32),
                            isLoved
                                ? Column(
                                    children: [
                                      const Icon(Icons.favorite, color: Colors.pinkAccent, size: 40),
                                      const SizedBox(height: 12),
                                      Text(
                                        "You already thanked $senderFullName ❤️", // Use sender's name
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          color: Colors.grey.shade600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  )
                                : FilledButton.tonal(
                                    onPressed: () async {
                                      if (widget.wishId == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Error: Wish ID is missing.')),
                                        );
                                        return;
                                      }
                                      try {
                                        debugPrint('WishScreen: Attempting to update wish status...');
                                        debugPrint('Wish ID: ${widget.wishId}, Recipient ID: ${Supabase.instance.client.auth.currentUser!.id}');
                                        await Supabase.instance.client
                                            .schema('social')
                                            .from('wishes')
                                            .update({
                                              'loved': true,
                                              'is_read': true,
                                            })
                                            .eq('id', widget.wishId!)
                                            .eq('recipient_id', Supabase.instance.client.auth.currentUser!.id);
                                        debugPrint('WishScreen: Wish status updated successfully.');

                                        debugPrint('WishScreen: Attempting to insert wish_loved notification...');
                                        debugPrint('Sender ID (of original wish): ${wish['sender_id']}, Current User ID: ${Supabase.instance.client.auth.currentUser!.id}, Wish ID: ${widget.wishId}');

                                        // Fetch the recipient's profile to get their name
                                        final currentUser = Supabase.instance.client.auth.currentUser;
                                        if (currentUser == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Error: User not logged in.')),
                                          );
                                          return;
                                        }
                                        final recipientProfile = await _friendService.fetchUserProfileById(currentUser.id);

                                        String notificationContent;
                                        if (recipientProfile != null) {
                                          notificationContent = '${recipientProfile.firstName} ${recipientProfile.lastName} loved your wish!';
                                        } else {
                                          notificationContent = 'Someone loved your wish!';
                                        }

                                        await _notificationService.insertNotification(
                                          userId: wish['sender_id'],
                                          type: 'wish_loved',
                                          content: notificationContent, // Use personalized content
                                          sourceId: currentUser.id,
                                          wishId: widget.wishId!,
                                        );
                                        debugPrint('WishScreen: Wish loved notification inserted successfully.');

                                        setState(() {
                                          wish['loved'] = true;
                                          wish['is_read'] = true;
                                        });
                                      } catch (e) {
                                        debugPrint('WishScreen Error: Failed to update wish or send notification: $e');
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error updating wish: $e')),
                                        );
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      backgroundColor: Colors.black,
                                    ),
                                    child: Text(
                                      "Thank $senderFullName", // Use sender's name
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// A reusable glassmorphism card
class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
