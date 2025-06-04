import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart'; // For generating UUIDs
import 'dart:io' as io; // Required for File class
import 'dart:typed_data'; // Required for Uint8List
// import 'package:birthday_app/models/friendship.dart'; // No longer needed as we use a direct SQL function

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  int _currentStep = 0;
  final TextEditingController _postTextController = TextEditingController();
  final List<Map<String, dynamic>> _selectedGroups = [];
  final List<Map<String, dynamic>> _selectedFriends = [];

  XFile? _imageFile;
  String? _imageUrl;
  bool _isLoading = false;

  List<Map<String, dynamic>> _availableGroups = [];
  List<Map<String, dynamic>> _availableFriends = [];

  @override
  void initState() {
    super.initState();
    _fetchGroupsAndFriends();
  }

  Future<void> _fetchGroupsAndFriends() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Fetch groups
      final groupMemberships = await Supabase.instance.client
          .schema('social')
          .from('group_members')
          .select('group_id')
          .eq('user_id', currentUser.id);

      if (groupMemberships != null && groupMemberships.isNotEmpty) {
        final groupIds = groupMemberships.map((e) => e['group_id'] as String).toList();
        final groupsResponse = await Supabase.instance.client
            .schema('social')
            .from('groups')
            .select('id, name')
            .inFilter('id', groupIds);
        _availableGroups = groupsResponse.cast<Map<String, dynamic>>();
      }

      // Fetch friends using the new SQL function
      final friendsResponse = await Supabase.instance.client
          .schema('social')
          .rpc('get_user_friends', params: {'target_user_id': currentUser.id});

      _availableFriends = friendsResponse.cast<Map<String, dynamic>>();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching groups or friends: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      _imageFile = image;
    });
  }

  Future<String?> _uploadImage(String postId) async {
    if (_imageFile == null) return null;

    setState(() {
      _isLoading = true;
    });

    try {
      final String fileName = p.basename(_imageFile!.path);
      final String imagePath = '$postId/$fileName'; // post_id/image.jpg standard
      final bytes = await _imageFile!.readAsBytes();


      final response = await Supabase.instance.client.storage
          .from('post-images') // Your bucket name
          .uploadBinary(
            imagePath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      if (response.isNotEmpty) {
        final String publicUrl = Supabase.instance.client.storage
            .from('post-images')
            .getPublicUrl(imagePath);
        return publicUrl;
      } else {
        throw Exception('Image upload failed: Response was empty');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
      return null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitPost() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      const uuid = Uuid();
      final postId = uuid.v4(); // Generate UUID for post_id

      String? uploadedImageUrl;
      if (_imageFile != null) {
        uploadedImageUrl = await _uploadImage(postId);
        if (uploadedImageUrl == null) {
          throw Exception('Failed to upload image');
        }
      }

      // Insert into social.posts
      final postResponse = await Supabase.instance.client
          .schema('social')
          .from('posts')
          .insert({
            'id': postId,
            'user_id': currentUser.id,
            'text': _postTextController.text.trim().isEmpty ? null : _postTextController.text.trim(),
            'image_url': uploadedImageUrl,
          })
          .select()
          .single();

      // Insert into social.post_recipients
      final List<Map<String, dynamic>> recipients = [];
      for (var group in _selectedGroups) {
        recipients.add({
          'post_id': postId,
          'group_id': group['id'],
          'user_id': null, // Only one of user_id or group_id should be non-null
        });
      }
      for (var friend in _selectedFriends) {
        recipients.add({
          'post_id': postId,
          'user_id': friend['id'],
          'group_id': null, // Only one of user_id or group_id should be non-null
        });
      }

      if (recipients.isNotEmpty) {
        await Supabase.instance.client
            .schema('social')
            .from('post_recipients')
            .insert(recipients);
      }

      // Create notifications for selected friends
      final List<Map<String, dynamic>> notifications = [];
      for (var friend in _selectedFriends) {
        notifications.add({
          'user_id': friend['id'],
          'type': 'new_post',
          'content': '${currentUser.email} posted something new!', // Customize notification content
          'source_id': currentUser.id, // The user who made the post
        });
      }

      if (notifications.isNotEmpty) {
        await Supabase.instance.client
            .schema('social')
            .from('notifications')
            .insert(notifications);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
      Navigator.pop(context); // Go back after submission
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting post: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: () {
                setState(() {
                  if (_currentStep < _getSteps().length - 1) {
                    _currentStep += 1;
                  } else {
                    _submitPost(); // Call submit function on last step
                  }
                });
              },
              onStepCancel: () {
                setState(() {
                  if (_currentStep > 0) {
                    _currentStep -= 1;
                  } else {
                    Navigator.pop(context); // Go back if on first step
                  }
                });
              },
              steps: _getSteps(),
            ),
    );
  }

  List<Step> _getSteps() {
    return [
      Step(
        title: const Text('Content'),
        content: Column(
          children: <Widget>[
            _imageFile == null
                ? Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          const Text('Upload Photo'),
                          ElevatedButton(
                            onPressed: _pickImage,
                            child: const Text('Choose Photo'),
                          ),
                        ],
                      ),
                    ),
                  )
                : FutureBuilder<Uint8List>(
                    future: _imageFile!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      }
                      return Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _postTextController,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'What was your favorite part?',
                hintText: 'Enter your birthday memories here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 0,
        state: _currentStep >= 0 ? StepState.indexed : StepState.disabled,
      ),
      Step(
        title: const Text('Share'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Choose who to share with:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Groups:'),
            ..._availableGroups.map((group) {
              return CheckboxListTile(
                title: Text(group['name'] ?? 'Unnamed Group'),
                value: _selectedGroups.any((selected) => selected['id'] == group['id']),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedGroups.add(group);
                    } else {
                      _selectedGroups.removeWhere((selected) => selected['id'] == group['id']);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 16),
            Text('Friends:'),
            ..._availableFriends.map((friend) {
              return CheckboxListTile(
                title: Text('${friend['first_name'] ?? ''} ${friend['last_name'] ?? ''}'.trim().isEmpty ? 'Unnamed Friend' : '${friend['first_name']} ${friend['last_name']}'),
                value: _selectedFriends.any((selected) => selected['id'] == friend['id']),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedFriends.add(friend);
                    } else {
                      _selectedFriends.removeWhere((selected) => selected['id'] == friend['id']);
                    }
                  });
                },
              );
            }),
          ],
        ),
        isActive: _currentStep >= 1,
        state: _currentStep >= 1 ? StepState.indexed : StepState.disabled,
      ),
      Step(
        title: const Text('Review'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Review your post:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _imageFile != null
                ? FutureBuilder<Uint8List>(
                    future: _imageFile!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                        return Image.memory(
                          snapshot.data!,
                          height: 100,
                          fit: BoxFit.cover,
                        );
                      }
                      return Container(
                        height: 100,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  )
                : const Text('No photo selected'),
            const SizedBox(height: 8),
            Text('Text: ${_postTextController.text.isEmpty ? '[No text]' : _postTextController.text}'),
            const SizedBox(height: 8),
            Text('Shared with Groups: ${_selectedGroups.map((g) => g['name']).join(', ')}'),
            Text('Shared with Friends: ${_selectedFriends.map((f) => f['username']).join(', ')}'),
          ],
        ),
        isActive: _currentStep >= 2,
        state: _currentStep >= 2 ? StepState.indexed : StepState.disabled,
      ),
    ];
  }

  @override
  void dispose() {
    _postTextController.dispose();
    super.dispose();
  }
}
