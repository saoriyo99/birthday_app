import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/services/notification_service.dart';

class WishScreen extends StatefulWidget {
  final String? wishId;

  const WishScreen({Key? key, this.wishId}) : super(key: key);

  @override
  _WishScreenState createState() => _WishScreenState();
}

class _WishScreenState extends State<WishScreen> with SingleTickerProviderStateMixin {
  late Future<dynamic> _wishFuture;
  late NotificationService _notificationService;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(Supabase.instance.client);
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
                                    "You already thanked them ❤️",
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
                                    await Supabase.instance.client
                                        .schema('social')
                                        .from('wishes')
                                        .update({
                                          'loved': true,
                                          'is_read': true,
                                        })
                                        .eq('id', widget.wishId!)
                                        .eq('recipient_id', Supabase.instance.client.auth.currentUser!.id);

                                    await _notificationService.insertNotification(
                                      userId: wish['sender_id'],
                                      type: 'wish_loved',
                                      content: 'They loved your wish!',
                                      sourceId: Supabase.instance.client.auth.currentUser!.id,
                                      wishId: widget.wishId!,
                                    );

                                    setState(() {
                                      wish['loved'] = true;
                                      wish['is_read'] = true;
                                    });
                                  } catch (e) {
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
                                child: const Text(
                                  "Thank them",
                                  style: TextStyle(
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
