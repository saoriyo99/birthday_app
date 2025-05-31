import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/screens/home_screen.dart'; // Assuming we navigate to home after acceptance

class ConfirmFriendshipScreen extends StatefulWidget {
  final String inviteCode;
  final String inviterId;
  final String inviterName; // To display "Do you want to be friends with X?"

  const ConfirmFriendshipScreen({
    super.key,
    required this.inviteCode,
    required this.inviterId,
    required this.inviterName,
  });

  @override
  State<ConfirmFriendshipScreen> createState() => _ConfirmFriendshipScreenState();
}

class _ConfirmFriendshipScreenState extends State<ConfirmFriendshipScreen> {
  bool _isProcessing = false;

  Future<void> _acceptFriendship() async {
    setState(() {
      _isProcessing = true;
    });

    final supabase = Supabase.instance.client;
    final recipientId = supabase.auth.currentUser?.id;

    if (recipientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to accept an invite.')),
      );
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    try {
      // First, fetch the invite to check its current status
      final List<Map<String, dynamic>> invites = await supabase
          .schema('social')
          .from('invites')
          .select()
          .eq('invite_code', widget.inviteCode);

      if (invites.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid invite code.')),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final invite = invites.first;
      if (invite['used'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This invite has already been used.')),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // 1. Mark invite as used
      // Ensure the invite is not already used to satisfy RLS policy
      await supabase.schema('social').from('invites').update({
        'used': true,
        'used_by': recipientId,
        'used_at': DateTime.now().toIso8601String(),
        'status': 'Accepted', // Set status to Accepted
      }).eq('invite_code', widget.inviteCode); // No need for .eq('used', false) here, as we checked it above

      // 2. Automatically create a friendship (bidirectional)
      await supabase.schema('social').from('friendships').insert([
        {'user_1_id': widget.inviterId, 'user_2_id': recipientId, 'status': 'accepted'},
        {'user_1_id': recipientId, 'user_2_id': widget.inviterId, 'status': 'accepted'},
      ]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friendship established!')),
      );

      // Navigate to home screen after successful acceptance
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error accepting invite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting invite: ${e.toString()}')),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _declineFriendship() async {
    setState(() {
      _isProcessing = true;
    });

    final supabase = Supabase.instance.client;
    final recipientId = supabase.auth.currentUser?.id;

    if (recipientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to decline an invite.')),
      );
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    try {
      // First, fetch the invite to check its current status
      final List<Map<String, dynamic>> invites = await supabase
          .schema('social')
          .from('invites')
          .select()
          .eq('invite_code', widget.inviteCode);

      if (invites.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid invite code.')),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      final invite = invites.first;
      if (invite['used'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This invite has already been used.')),
        );
        setState(() {
          _isProcessing = false;
        });
        return;
      }

      // Mark invite as used and status as Declined
      await supabase.schema('social').from('invites').update({
        'used': true,
        'used_by': recipientId,
        'used_at': DateTime.now().toIso8601String(),
        'status': 'Declined', // Set status to Declined
      }).eq('invite_code', widget.inviteCode); // No need for .eq('used', false) here, as we checked it above

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friendship invite declined.')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error declining invite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error declining invite: ${e.toString()}')),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friendship Invitation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Do you want to be friends with ${widget.inviterName}?',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _isProcessing
                  ? const CircularProgressIndicator()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _acceptFriendship,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: const Text('Yes', style: TextStyle(fontSize: 18)),
                        ),
                        ElevatedButton(
                          onPressed: _declineFriendship,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          child: const Text('No', style: TextStyle(fontSize: 18)),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
