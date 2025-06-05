import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/services/notification_service.dart';

class WishScreen extends StatefulWidget {
  final String wishId;

  const WishScreen({Key? key, required this.wishId}) : super(key: key);

  @override
  _WishScreenState createState() => _WishScreenState();
}

class _WishScreenState extends State<WishScreen> {
  late Future<dynamic> _wishFuture;
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(Supabase.instance.client);
    _wishFuture = loadWish();
  }

  Future<dynamic> loadWish() async {
    final response = await Supabase.instance.client
        .schema('social')
        .from('wishes')
        .select('id, sender_id, recipient_id, message, type, loved, is_read, created_at')
        .eq('id', widget.wishId)
        .single();

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _wishFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        final wish = snapshot.data;
        final isLoved = wish['loved'] as bool;
        final message = wish['message'] as String;

        return Scaffold(
          appBar: AppBar(title: Text("Wish")),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Message: $message"),
              const SizedBox(height: 20),
              isLoved
                ? Text("You already thanked them ❤️")
                : ElevatedButton(
                    onPressed: () async {
                      await Supabase.instance.client
                          .schema('social')
                          .from('wishes')
                          .update({
                            'loved': true,
                            'is_read': true,
                          })
                          .eq('id', widget.wishId)
                          .eq('recipient_id', Supabase.instance.client.auth.currentUser!.id);

                      // Now send notification back to sender
                      await _notificationService.insertNotification(
                        userId: wish['sender_id'],
                        type: 'wish_loved',
                        content: 'They loved your wish!',
                        sourceId: Supabase.instance.client.auth.currentUser!.id,
                        wishId: widget.wishId,
                      );

                      // Refresh screen
                      setState(() {
                        _wishFuture = loadWish();
                      });
                    },
                    child: const Text("❤️ Thank them for the wish"),
                  ),
            ],
          ),
        );
      },
    );
  }
}
