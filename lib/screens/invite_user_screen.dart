import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart'; // For sharing the link
import 'package:flutter/services.dart'; // For Clipboard
import 'package:birthday_app/constants/urls.dart';

class InviteUserScreen extends StatefulWidget {
  final bool initialModeIsGroup;
  final String? groupId; // New: Optional groupId for existing groups
  const InviteUserScreen({super.key, this.initialModeIsGroup = false, this.groupId});

  @override
  State<InviteUserScreen> createState() => _InviteUserScreenState();
}

class _InviteUserScreenState extends State<InviteUserScreen> {
  // Friend related state
  String _inviteCode = '';
  String _friendShareLink = 'Generating invite link...';

  // Group related state
  final _groupFormKey = GlobalKey<FormState>();
  final TextEditingController _groupNameController = TextEditingController();
  String? _groupType;
  bool _hasEndDate = false;
  final TextEditingController _endDateController = TextEditingController();
  final List<String> _groupTypes = ['Family', 'Friends', 'Coworkers', 'Other'];
  String _groupShareLink = 'Generating group invite link...';
  bool _groupCreatedSuccessfully = false; // New state for group creation success

  // Common state
  bool _isLoading = true;
  String _errorMessage = '';
  late bool _isGroupMode; // New switch state, initialized in initState

  @override
  void initState() {
    super.initState();
    _isGroupMode = widget.initialModeIsGroup || widget.groupId != null; // If groupId is provided, it's group mode
    if (_isGroupMode) {
      if (widget.groupId != null) {
        // If an existing group ID is provided, generate link directly
        _generateGroupInviteLink(existingGroupId: widget.groupId);
      } else {
        // No initial link generation for new group mode, as it requires form submission
        _isLoading = false; // Set loading to false for new group mode initially
        _groupCreatedSuccessfully = false; // Ensure form is shown initially for new group mode
      }
    } else {
      _generateInviteLink(); // Initial generation for friend mode
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDateController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
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

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(days: 7));

      // Insert into social.invites table
      await Supabase.instance.client.schema('social').from('invites').insert({
        'inviter_id': inviterId,
        'invite_code': newInviteCode,
        'used': false,
        'max_uses': 1,
        'type': 'friend',
        'expires_at': expiresAt.toIso8601String(),
      });

      // Construct the invite link
      final link = inviteLink(newInviteCode);

      setState(() {
        _inviteCode = newInviteCode;
        _friendShareLink = link;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate friend invite link: ${e.toString()}';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectableText(_errorMessage)),
      );
    }
  }

  Future<void> _generateGroupInviteLink({String? existingGroupId}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final inviterId = Supabase.instance.client.auth.currentUser?.id;
      if (inviterId == null) {
        throw Exception('User not logged in.');
      }

      String groupIdToUse;
      if (existingGroupId != null) {
        groupIdToUse = existingGroupId;
        // Fetch group details to display name in share content if needed
        final groupData = await Supabase.instance.client
            .schema('social')
            .from('groups')
            .select('name')
            .eq('id', groupIdToUse)
            .single();
        _groupNameController.text = groupData['name'] as String; // Set name for display
      } else {
        // 1. Create the group first
        final groupResponse = await Supabase.instance.client
            .schema('social')
            .from('groups')
            .insert({
              'name': _groupNameController.text,
              'type': _groupType,
              'end_date': _hasEndDate && _endDateController.text.isNotEmpty
                  ? DateTime.parse(_endDateController.text).toIso8601String()
                  : null,
            })
            .select('id') // Select the ID of the newly created group
            .single();
        groupIdToUse = groupResponse['id'] as String;

        // Add current user to group_members if creating a new group
        final inviteResponse = await Supabase.instance.client.schema('social').from('invites').insert({
          'inviter_id': inviterId,
          'invite_code': const Uuid().v4(), // Generate a temporary invite code for the creator
          'used': true, // Mark as used by the creator
          'max_uses': 1,
          'type': 'group_creator', // Special type for the creator's entry
          'expires_at': null,
          'group_id': groupIdToUse,
        }).select('id').single();

        await Supabase.instance.client.schema('social').from('group_members').insert({
          'group_id': groupIdToUse,
          'user_id': inviterId,
          'invite_id': inviteResponse['id'] as String,
        });
      }

      // Generate invite code and insert into social.invites table with group_id
      const uuid = Uuid();
      final newGroupInviteCode = uuid.v4();

      await Supabase.instance.client.schema('social').from('invites').insert({
        'inviter_id': inviterId,
        'invite_code': newGroupInviteCode,
        'used': false,
        'max_uses': 9999, // Groups can have multiple uses
        'type': 'group',
        'expires_at': _hasEndDate && _endDateController.text.isNotEmpty
            ? DateTime.parse(_endDateController.text).toIso8601String()
            : null, // Optional end date
        'group_id': groupIdToUse, // Link invite to the group
      });

      final link = groupInviteLink(newGroupInviteCode);

      setState(() {
        _groupShareLink = link;
        _isLoading = false;
        _groupCreatedSuccessfully = true; // Set to true on success
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create group and generate invite link: ${e.toString()}';
        _isLoading = false;
        _groupCreatedSuccessfully = false; // Ensure form is shown on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: SelectableText(_errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupId != null
            ? 'Add Members to ${_groupNameController.text}' // Display group name
            : (_isGroupMode ? 'Create Group' : 'Add Friend')),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          if (widget.groupId == null) // Only show segmented button if not in existing group mode
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(
                    value: false,
                    label: Text('Friend'),
                    icon: Icon(Icons.person_add),
                  ),
                  ButtonSegment<bool>(
                    value: true,
                    label: Text('Group'),
                    icon: Icon(Icons.group_add),
                  ),
                ],
                selected: <bool>{_isGroupMode},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isGroupMode = newSelection.first;
                    _isLoading = true; // Reset loading state when switching modes
                    _errorMessage = ''; // Clear error message
                    _groupCreatedSuccessfully = false; // Reset group creation state on mode change

                    if (!_isGroupMode && _friendShareLink == 'Generating invite link...') {
                      // Only generate friend link if it hasn't been generated yet
                      _generateInviteLink();
                    } else if (_isGroupMode && _groupShareLink == 'Generating group invite link...') {
                      // No automatic generation for group mode, it's done on form submit
                      _isLoading = false;
                    } else {
                      _isLoading = false; // If links already exist, no loading needed
                    }
                  });
                },
              ),
            ),
          Expanded(
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
                              onPressed: _isGroupMode
                                  ? () => _generateGroupInviteLink(existingGroupId: widget.groupId)
                                  : _generateInviteLink,
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      : widget.groupId != null // If groupId is provided, always show share content
                          ? _buildGroupShareContent(context)
                          : (_isGroupMode
                              ? (_groupCreatedSuccessfully ? _buildGroupShareContent(context) : _buildGroupFormContent(context))
                              : _buildFriendContent(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendContent(BuildContext context) {
    return Center( // Wrap with Center to ensure horizontal centering
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
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
          SelectableText(
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
          const SizedBox(height: 16),
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
    );
  }

  Widget _buildGroupFormContent(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _groupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextFormField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a group name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _groupType,
              decoration: const InputDecoration(
                labelText: 'Type',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select Group Type'),
              onChanged: (String? newValue) {
                setState(() {
                  _groupType = newValue;
                });
              },
              items: _groupTypes.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a group type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _hasEndDate,
                  onChanged: (bool? value) {
                    setState(() {
                      _hasEndDate = value ?? false;
                      if (!_hasEndDate) {
                        _endDateController.clear();
                      }
                    });
                  },
                ),
                const Text('Set End Date'),
              ],
            ),
            if (_hasEndDate) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _endDateController,
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (_hasEndDate && (value == null || value.isEmpty)) {
                    return 'Please select an end date';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_groupFormKey.currentState!.validate()) {
                  _generateGroupInviteLink(); // Generate group link on submit
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                'Create Group',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupShareContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const Text(
            'Share Group:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          QrImageView(
            data: _groupShareLink,
            version: QrVersions.auto,
            size: 200.0, // Increased size for better visibility
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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Share.share(_groupShareLink);
            },
            icon: const Icon(Icons.share),
            label: const Text(
              'Share Group Link',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _groupShareLink));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group invite link copied to clipboard!')),
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
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _groupCreatedSuccessfully = false; // Go back to form
                _groupNameController.clear();
                _groupType = null;
                _hasEndDate = false;
                _endDateController.clear();
                _groupShareLink = 'Generating group invite link...'; // Reset link display
              });
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: const Text(
              'Create Another Group',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
