import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart'; // For sharing the link
import 'package:flutter/services.dart'; // For Clipboard

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  String _inviteCode = '';
  String _friendShareLink = 'Generating invite link...';
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _generateInviteLink();
  }

  Future<void> _generateInviteLink() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final inviterId = Supabase.instance.client.auth.currentUser?.id;
      if (inviterId == null) {
        throw Exception('User not logged in.');
      }

      const uuid = Uuid();
      final newInviteCode = uuid.v4();

      // Insert into social.invites table
      await Supabase.instance.client.schema('social').from('invites').insert({
        'inviter_id': inviterId,
        'invite_code': newInviteCode,
        'used': false,
      });

      // Construct the invite link
      // Replace 'your-app.com' with your actual app's domain or deep link scheme
      final link = 'https://saoriyo99.github.io/birthday_app/#/invite?code=$newInviteCode';

      setState(() {
        _inviteCode = newInviteCode;
        _friendShareLink = link;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate invite link: ${e.toString()}';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const CircularProgressIndicator()
              : _errorMessage.isNotEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _generateInviteLink,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Text(
                          'Scan this QR code to add me!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        QrImageView(
                          data: _friendShareLink,
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
                        Text(
                          'Share this link: $_friendShareLink',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Share.share(_friendShareLink);
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
                        const SizedBox(height: 16), // Add some spacing
                        ElevatedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _friendShareLink));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invite link copied to clipboard!')),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text(
                            'Copy Link',
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
