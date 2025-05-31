import 'package:flutter/material.dart';

class ConfirmFriendshipScreen extends StatelessWidget {
  final String inviteCode;
  final String inviterId;
  final String inviterName;

  const ConfirmFriendshipScreen({
    super.key,
    required this.inviteCode,
    required this.inviterId,
    required this.inviterName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Friendship'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'You have been invited by $inviterName to be friends!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              Text('Invite Code: $inviteCode'),
              Text('Inviter ID: $inviterId'),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement logic to accept friendship
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Friendship acceptance logic not yet implemented.')),
                  );
                  Navigator.pop(context); // Go back
                },
                child: const Text('Accept Friendship'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Go back
                },
                child: const Text('Decline'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
