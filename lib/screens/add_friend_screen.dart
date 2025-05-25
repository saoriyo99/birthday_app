import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // For QR code generation

class AddFriendScreen extends StatelessWidget {
  const AddFriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder for the link to share. In a real app, this would be dynamic.
    const String friendShareLink = 'https://birthdayapp.com/addfriend/jane_doe_invite';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Scan this QR code to add me!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              QrImageView(
                data: friendShareLink,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
                errorStateBuilder: (cxt, err) {
                  return const Center(
                    child: Text(
                      'Uh oh! Something went wrong with QR code generation.',
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Simulate sharing the link
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sharing link: $friendShareLink')),
                  );
                  // In a real app, you would use a package like `share_plus`
                  // Share.share(friendShareLink);
                },
                icon: const Icon(Icons.share),
                label: const Text(
                  'Share Link',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
