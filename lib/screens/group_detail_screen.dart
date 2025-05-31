import 'package:flutter/material.dart';
import 'package:birthday_app/models/group.dart';
import 'package:birthday_app/models/group_member.dart';
import 'package:birthday_app/models/post.dart'; // Assuming a Post model exists or will be created
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:birthday_app/screens/add_friend_screen.dart'; // Import AddFriendScreen

class GroupDetailScreen extends StatefulWidget {
  final Group group;

  const GroupDetailScreen({Key? key, required this.group}) : super(key: key);

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Post> _posts = [];
  Map<String, String> _userNames = {}; // Map to store user IDs to names
  bool _isLoadingPosts = true;
  String? _postsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchGroupPosts(); // Fetch posts when the screen initializes
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddFriendScreen(groupId: widget.group.id),
            ),
          );
        },
        child: const Icon(Icons.add),
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
          .select('posts(id, text, image_url, user_id, created_at), group_id') // Select posts and group_id
          .eq('group_id', widget.group.id)
          .order('created_at', ascending: false); // Order by most recent (from post_recipients)

      if (response == null) {
        throw Exception('Failed to fetch posts');
      }

      final List<Future<Post>> postFutures = response.map((recipientMap) async {
        final postMap = recipientMap['posts'] as Map<String, dynamic>;
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
              print('Warning: Image URL does not match expected Supabase public URL format: $rawImageUrl');
            }
          } catch (e) {
            print('Error generating signed URL for $rawImageUrl: $e');
            imageUrl = null; // Fallback to null if URL generation fails
          }
        }
        return Post(
          id: postMap['id'] as String,
          text: postMap['text'] as String?,
          imageUrl: imageUrl,
          userId: postMap['user_id'] as String,
          timestamp: DateTime.parse(postMap['created_at'] as String),
          groupId: recipientMap['group_id'] as String,
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
                  if (post.text != null && post.text!.isNotEmpty)
                    Text(
                      post.text!,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  if (post.text != null && post.text!.isNotEmpty && post.imageUrl != null && post.imageUrl!.isNotEmpty)
                    const SizedBox(height: 8.0),
                  Text(
                    'Posted by: ${_userNames[post.userId] ?? 'Unknown User'}', // Display user name
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'Date: ${post.timestamp.toLocal().toString().split(' ')[0]}', // Format date
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

  Widget _buildMembersTab() {
    // TODO: Fetch and display members for the group
    // For now, a placeholder list
    final List<GroupMember> groupMembers = widget.group.members; // Assuming Group model has a 'members' field

    return groupMembers.isEmpty
        ? const Center(child: Text('No members yet.'))
        : ListView.builder(
            itemCount: groupMembers.length,
            itemBuilder: (context, index) {
              final member = groupMembers[index];
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(member.name), // Assuming GroupMember has a 'name' field
                  subtitle: Text(member.role), // Assuming GroupMember has a 'role' field
                ),
              );
            },
          );
  }
}
