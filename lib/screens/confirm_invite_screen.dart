import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/screens/home_screen.dart'; // Assuming we navigate to home after acceptance

class ConfirmInviteScreen extends StatefulWidget {
  final String inviteCode;

  const ConfirmInviteScreen({
    super.key,
    required this.inviteCode,
  });

  @override
  State<ConfirmInviteScreen> createState() => _ConfirmInviteScreenState();
}

class _ConfirmInviteScreenState extends State<ConfirmInviteScreen> {
  bool _isProcessing = false;
  bool _isLoading = true;
  String _errorMessage = '';

  String? _inviteType;
  String? _inviterId;
  String? _inviterName;
  String? _groupId;
  String? _groupName;

  @override
  void initState() {
    super.initState();
    _fetchInviteDetails();
  }

  Future<void> _fetchInviteDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final supabase = Supabase.instance.client;

    try {
      final List<Map<String, dynamic>> invites = await supabase
          .schema('social')
          .from('invites')
          .select('*, inviter:inviter_id(first_name, last_name), group:group_id(name)') // Fetch inviter first and last name, and group name
          .eq('invite_code', widget.inviteCode);

      if (invites.isEmpty) {
        setState(() {
          _errorMessage = 'Invalid invite code.';
          _isLoading = false;
        });
        debugPrint('Invite error: $_errorMessage');
        return;
      }

      final invite = invites.first;

      // Check if the invite has expired
      if (invite['expires_at'] != null) {
        final expiresAt = DateTime.parse(invite['expires_at']);
        if (DateTime.now().isAfter(expiresAt)) {
          setState(() {
            _errorMessage = 'This invite has expired. Please ask for a new link.';
            _isLoading = false;
          });
          debugPrint('Invite error: $_errorMessage');
          return;
        }
      }

      if (invite['used'] == true) {
        setState(() {
          _errorMessage = 'This invite has already been used.';
          _isLoading = false;
        });
        debugPrint('Invite error: $_errorMessage');
        return;
      }

      setState(() {
        _inviteType = invite['type'] as String?;
        _inviterId = invite['inviter_id'] as String?;
        _inviterName = (invite['inviter'] as Map<String, dynamic>?)?['first_name'] as String? ?? '';
        final inviterLastName = (invite['inviter'] as Map<String, dynamic>?)?['last_name'] as String? ?? '';
        if (_inviterName!.isNotEmpty && inviterLastName.isNotEmpty) {
          _inviterName = '$_inviterName $inviterLastName';
        } else if (inviterLastName.isNotEmpty) {
          _inviterName = inviterLastName;
        }
        _groupId = invite['group_id'] as String?;
        _groupName = (invite['group'] as Map<String, dynamic>?)?['name'] as String?;
        _isLoading = false;
      });

      debugPrint('Fetched inviterName: $_inviterName, groupName: $_groupName');

      if (_inviteType == null || (_inviteType == 'friend' && _inviterId == null) || (_inviteType == 'group' && _groupId == null)) {
        setState(() {
          _errorMessage = 'Incomplete invite details.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching invite details: $e');
      setState(() {
        _errorMessage = 'Error fetching invite details: ${e.toString()}';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    }
  }

  Future<void> _processInvite(bool accept) async {
    debugPrint('Processing invite: accept=$accept');
    setState(() {
      _isProcessing = true;
    });

    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to respond to an invite.')),
      );
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    try {
      // Mark invite as used and set status
      await supabase.schema('social').from('invites').update({
        'used': true,
        'used_by': currentUserId,
        'used_at': DateTime.now().toIso8601String(),
        'status': accept ? 'Accepted' : 'Declined',
      }).eq('invite_code', widget.inviteCode);

      if (accept) {
        if (_inviteType == 'friend') {
          if (_inviterId == null) {
            throw Exception('Inviter ID not found for friend invite.');
          }
          // Create bidirectional friendship
          await supabase.schema('social').from('friendships').insert([
            {'user_1_id': _inviterId!, 'user_2_id': currentUserId, 'status': 'accepted'}          ]);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Friendship established!')),
          );
        } else if (_inviteType == 'group') {
          if (_groupId == null) {
            throw Exception('Group ID not found for group invite.');
          }
          // Check if user is already a member
          final existingMembership = await supabase
              .schema('social')
              .from('group_members')
              .select('id')
              .eq('group_id', _groupId!)
              .eq('user_id', currentUserId);

          if (existingMembership.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You are already a member of this group!')),
            );
          } else {
            // Add user to group_members
            await supabase.schema('social').from('group_members').insert({
              'group_id': _groupId!,
              'user_id': currentUserId,
              // 'invite_id': inviteId, // This would require fetching the invite's actual ID from the invites table
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Successfully joined group "$_groupName"!')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_inviteType == 'group' ? 'Group' : 'Friendship'} invite declined.')),
        );
      }

      // Navigate to home screen after processing
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error processing invite: $e');
      setState(() {
        _errorMessage = 'Error processing invite: ${e.toString()}';
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String titleText = 'Invitation';
    String messageText = 'Loading invitation details...';

    if (!_isLoading && _errorMessage.isEmpty) {
      if (_inviteType == 'friend' && _inviterName != null) {
        titleText = 'Friendship Invitation';
        messageText = 'Do you want to be friends with $_inviterName?';
      } else if (_inviteType == 'group' && _groupName != null) {
        titleText = 'Group Invitation';
        messageText = '$_inviterName invited you to join "$_groupName".';
      } else {
        titleText = 'Invitation';
        messageText = 'Unknown invitation type or details missing.';
      }
    } else if (_errorMessage.isNotEmpty) {
      titleText = 'Error';
      messageText = _errorMessage;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText),
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
                          messageText,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                              (route) => false,
                            );
                          },
                          child: const Text('Go to Home'),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          messageText,
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
                                    onPressed: () => _processInvite(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                    ),
                                    child: const Text('Yes', style: TextStyle(fontSize: 18)),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _processInvite(false),
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
