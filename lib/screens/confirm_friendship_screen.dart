import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConfirmFriendshipScreen extends StatefulWidget {
  final String friendId;

  const ConfirmFriendshipScreen({
    super.key,
    required this.friendId,
  });

  @override
  State<ConfirmFriendshipScreen> createState() => _ConfirmFriendshipScreenState();
}

class _ConfirmFriendshipScreenState extends State<ConfirmFriendshipScreen> {
  String? _inviterName;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchInviterDetails();
  }

  Future<void> _fetchInviterDetails() async {
    try {
      final response = await Supabase.instance.client
          .schema('social')
          .from('users')
          .select('full_name')
          .eq('id', widget.friendId)
          .limit(1)
          .maybeSingle();

      if (response != null && response['full_name'] != null) {
        setState(() {
          _inviterName = response['full_name'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Inviter details not found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching inviter details: $e';
        _isLoading = false;
      });
      debugPrint('Error fetching inviter details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Friendship'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage != null
                ? SelectableText(_errorMessage!)
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'You have been invited by $_inviterName to be friends!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 20),
                        Text('Friend ID: ${widget.friendId}'),
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
