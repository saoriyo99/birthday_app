import 'package:flutter/material.dart';

class SendHbWishScreen extends StatelessWidget {
  final String friendName;
  final int friendAge;
  final String friendBirthday;
  final String friendGroups;

  const SendHbWishScreen({
    super.key,
    required this.friendName,
    required this.friendAge,
    required this.friendBirthday,
    required this.friendGroups,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wish $friendName'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blueGrey, // Placeholder for friend's image
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              friendName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Age $friendAge',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              friendBirthday,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              'Groups: $friendGroups',
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sent! You wished $friendName HB!')),
                );
                // TODO: Implement actual wish sending logic
                // After sending, maybe navigate back or show a confirmation screen
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(
                'Wish $friendName HB!',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
