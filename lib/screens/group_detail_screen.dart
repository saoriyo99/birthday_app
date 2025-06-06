import 'package:flutter/material.dart';
import 'package:birthday_app/models/group.dart';
import 'package:birthday_app/models/post.dart';
import 'package:birthday_app/models/group_member_profile.dart'; // Import the new model
import 'package:birthday_app/services/group_service.dart'; // Import GroupService
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/screens/invite_user_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({Key? key, required this.group}) : super(key: key);

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late GroupService _groupService; // Declare GroupService
  List<Post> _posts = [];
  Map<String, String> _userNames = {};
  bool _isLoadingPosts = true;
  String? _postsError;

  List<GroupMemberProfile> _members = []; // New state for members
  bool _isLoadingMembers = true; // New state for member loading
  String? _membersError; // New state for member error
  bool _isEditingGroupName = false; // New state for editing group name
  late TextEditingController _groupNameController; // Controller for editing group name
  late Group _currentGroup; // Mutable group object

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _groupService = GroupService(Supabase.instance.client); // Initialize GroupService
    _currentGroup = widget.group; // Initialize mutable group object
    _groupNameController = TextEditingController(text: _currentGroup.name); // Initialize controller
    _fetchGroupPosts();
    _fetchGroupMembers(); // Fetch members when the screen initializes
  }

  @override
  void dispose() {
    _tabController.dispose();
    _groupNameController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Always pop with true to indicate a potential change, triggering refresh on home screen
        Navigator.pop(context, true);
        return false; // Prevent the default back button behavior as we've handled it
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_currentGroup.name), // Use _currentGroup.name
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Posts'),
              Tab(text: 'Members'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            _buildMembersTab(),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchGroupPosts() async {
    setState(() {
      _isLoadingPosts = true;
      _postsError = null;
    });
    try {
      final response = await Supabase.instance.client
          .schema('social')
          .from('post_recipients') // Query post_recipients table
          .select('posts(id, text, image_url, user_id, created_at, users(first_name, last_name)), group_id') // Select posts and group_id, and user names
          .eq('group_id', _currentGroup.id) // Use _currentGroup.id
          .order('created_at', ascending: false); // Order by most recent (from post_recipients)

      if (response == null) {
        throw Exception('Failed to fetch posts');
      }

      final List<Future<Post>> postFutures = response.map((recipientMap) async {
        final postMap = recipientMap['posts'] as Map<String, dynamic>;
        final userMap = postMap['users'] as Map<String, dynamic>; // Extract user data
        String? imageUrl; // Declare imageUrl once here
        final String? rawImageUrl = postMap['image_url'] as String?;
        if (rawImageUrl != null && rawImageUrl.isNotEmpty) {
          try {
            final Uri uri = Uri.parse(rawImageUrl);
            // Expected path segments: ['storage', 'v1', 'object', 'public', 'post-images', 'path', 'to', 'file']
            // We need 'path/to/file'
            if (uri.pathSegments.length >= 6 && uri.pathSegments[4] == 'post-images') {
              final String pathInBucket = uri.pathSegments.sublist(5).join('/');
              imageUrl = await Supabase.instance.client.storage.from('post-images').createSignedUrl(pathInBucket, 60); // Generate signed URL for 60 seconds
            } else {
              // If it's not a Supabase public URL, assume it's already a direct URL or log a warning
              imageUrl = rawImageUrl; // Use as is, or log a warning
              debugPrint('Warning: Image URL does not match expected Supabase public URL format: $rawImageUrl');
            }
          } catch (e) {
            debugPrint('Error generating signed URL for $rawImageUrl: $e');
            imageUrl = null; // Fallback to null if URL generation fails
          }
        }
        return Post(
          id: postMap['id'] as String,
          text: postMap['text'] as String, // Changed from String? to String
          imageUrl: imageUrl,
          userId: postMap['user_id'] as String,
          createdAt: DateTime.parse(postMap['created_at'] as String), // Changed from timestamp to createdAt
          userFirstName: userMap['first_name'] as String, // Added
          userLastName: userMap['last_name'] as String, // Added
        );
      }).toList();

      final List<Post> fetchedPosts = await Future.wait(postFutures);

      // Collect unique user IDs from fetched posts
      final Set<String> uniqueUserIds = fetchedPosts.map((post) => post.userId).toSet();

      // Fetch user names for these IDs
      if (uniqueUserIds.isNotEmpty) {
        final usersResponse = await Supabase.instance.client
            .schema('social')
            .from('users')
            .select('id, first_name, last_name') // Select first_name and last_name
            .inFilter('id', uniqueUserIds.toList());

        if (usersResponse != null) {
          setState(() {
            _userNames = {
              for (var user in usersResponse)
                user['id'] as String: '${user['first_name']} ${user['last_name']}', // Combine names
            };
          });
        }
      }

      setState(() {
        _posts = fetchedPosts;
        _isLoadingPosts = false;
      });
    } catch (e) {
      setState(() {
        _postsError = 'Error loading posts: $e';
        _isLoadingPosts = false;
      });
    }
  }

  Widget _buildPostsTab() {
    if (_isLoadingPosts) {
      return const Center(child: CircularProgressIndicator());
    } else if (_postsError != null) {
      return Center(child: Text(_postsError!));
    } else if (_posts.isEmpty) {
      return const Center(child: Text('No posts yet.'));
    } else {
      return ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            elevation: 4.0, // Adds a shadow for a framed look
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0), // Rounded corners
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: 400, // Limit to 400 logical pixels
                          ),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                post.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 100),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ), // This closing parenthesis was missing
                  if (post.text.isNotEmpty) // Changed from post.text != null && post.text!.isNotEmpty
                    Text(
                      post.text, // Changed from post.text!
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  if (post.text.isNotEmpty && post.imageUrl != null && post.imageUrl!.isNotEmpty) // Changed from post.text != null && post.text!.isNotEmpty
                    const SizedBox(height: 8.0),
                  Text(
                    'Posted by: ${_userNames[post.userId] ?? 'Unknown User'}', // Display user name
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Date: ${post.createdAt.toLocal().toString().split(' ')[0]}', // Changed from timestamp to createdAt
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Future<void> _fetchGroupMembers() async {
    setState(() {
      _isLoadingMembers = true;
      _membersError = null;
    });
    try {
      final fetchedMembers = await _groupService.fetchGroupMembers(_currentGroup.id); // Use _currentGroup.id
      setState(() {
        _members = fetchedMembers;
        _isLoadingMembers = false;
      });
    } catch (e) {
      setState(() {
        _membersError = 'Error loading members: $e';
        _isLoadingMembers = false;
      });
    }
  }

  Widget _buildMembersTab() {
    if (_isLoadingMembers) {
      return const Center(child: CircularProgressIndicator());
    } else if (_membersError != null) {
      return Center(child: Text(_membersError!));
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Center the content horizontally
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // Center the text within this column
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _isEditingGroupName
                        ? Expanded(
                            child: TextField(
                              controller: _groupNameController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              ),
                              onSubmitted: (newName) {
                                _updateGroupName(newName);
                              },
                            ),
                          )
                        : Text(
                            'Group Name: ${_currentGroup.name}', // Use _currentGroup.name
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center, // Center the text itself
                          ),
                    IconButton(
                      icon: Icon(_isEditingGroupName ? Icons.check : Icons.edit),
                      onPressed: () {
                        if (_isEditingGroupName) {
                          _updateGroupName(_groupNameController.text);
                        } else {
                          // When entering edit mode, ensure the controller has the current group name
                          _groupNameController.text = _currentGroup.name;
                        }
                        setState(() {
                          _isEditingGroupName = !_isEditingGroupName;
                        });
                      },
                    ),
                    Visibility(
                      visible: _isEditingGroupName,
                      child: IconButton(
                        icon: const Icon(Icons.close), // Cancel button
                        onPressed: () {
                          setState(() {
                            _groupNameController.text = _currentGroup.name; // Revert text
                            _isEditingGroupName = false; // Exit editing mode
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Members: ${_members.length}',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center, // Center the text itself
                ),
                const SizedBox(height: 16), // Add some space between text and button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InviteUserScreen(groupId: _currentGroup.id), // Use _currentGroup.id
                      ),
                    );
                  },
                  child: const Text('Invite Members'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _members.isEmpty
                ? const Center(child: Text('No members yet.'))
                : ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Center(child: Text(member.fullName)), // Center member name
                          subtitle: member.birthday != null
                              ? Center(child: Text('Birthday: ${member.birthday!.month}/${member.birthday!.day}')) // Center birthday
                              : const Center(child: Text('Birthday: Not provided')), // Center birthday
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    }
  }

  Future<void> _updateGroupName(String newName) async {
    if (newName.trim().isEmpty || newName == _currentGroup.name) {
      setState(() {
        _isEditingGroupName = false;
      });
      return;
    }

    try {
      await _groupService.updateGroupName(_currentGroup.id, newName);
      setState(() {
        _currentGroup = _currentGroup.copyWith(name: newName); // Create a new Group object with updated name
        _isEditingGroupName = false;
        _groupNameController.text = newName; // Update the text controller
        // _groupNameChanged = true; // Removed this flag as it's no longer used in dispose
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update group name: $e')),
      );
      setState(() {
        _isEditingGroupName = false; // Exit editing mode on error
        _groupNameController.text = _currentGroup.name; // Revert text on error
      });
    }
  }
}
