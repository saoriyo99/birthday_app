import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/models/post.dart'; // Assuming a Post model exists or will be created
import 'package:birthday_app/models/user_profile.dart'; // Assuming a UserProfile model exists
import 'package:birthday_app/services/post_service.dart';
import 'package:birthday_app/services/group_service.dart';
import 'package:birthday_app/services/friend_service.dart';

class SeePostScreen extends StatefulWidget {
  final String? postId;
  final String? selectedGroupId;
  final String? selectedFriendId;

  const SeePostScreen({
    super.key,
    this.postId,
    this.selectedGroupId,
    this.selectedFriendId,
  });

  @override
  State<SeePostScreen> createState() => _SeePostScreenState();
}

class _SeePostScreenState extends State<SeePostScreen> {
  Post? _singlePost;
  List<Post> _posts = [];
  UserProfile? _postCreator;
  bool _isLoading = true;
  String? _errorMessage;

  late PostService _postService;
  late GroupService _groupService;
  late FriendService _friendService;

  @override
  void initState() {
    super.initState();
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    _postService = PostService(Supabase.instance.client);
    _groupService = GroupService(Supabase.instance.client);
    _friendService = FriendService(Supabase.instance.client);
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() {
          _errorMessage = 'User not logged in.';
          _isLoading = false;
        });
        return;
      }

      debugPrint('SeePostScreen - selectedFriendId: ${widget.selectedFriendId}');
      debugPrint('SeePostScreen - selectedGroupId: ${widget.selectedGroupId}');

      if (widget.postId != null) {
        // Fetch a single post
        final postData = await Supabase.instance.client
            .schema('social')
            .from('posts')
            .select('*, post_recipients(*)')
            .eq('id', widget.postId!)
            .single();

        final post = await Post.fromMapAsync(postData);
        final postRecipients = postData['post_recipients'] as List<dynamic>;

        bool canView = false;
        if (post.userId == currentUserId) {
          canView = true;
        } else {
          for (var recipient in postRecipients) {
            if (recipient['user_id'] == currentUserId) {
              canView = true;
              break;
            }
            if (recipient['group_id'] != null) {
              final groupMembers = await Supabase.instance.client
                  .schema('social')
                  .from('group_members')
                  .select('user_id')
                  .eq('group_id', recipient['group_id'])
                  .eq('user_id', currentUserId)
                  .limit(1)
                  .maybeSingle();
              if (groupMembers != null) {
                canView = true;
                break;
              }
            }
          }
        }

        if (!canView) {
          setState(() {
            _errorMessage = 'You do not have permission to view this post.';
            _isLoading = false;
          });
          return;
        }

        final creatorData = await Supabase.instance.client
            .schema('social')
            .from('users')
            .select('*')
            .eq('id', post.userId)
            .single();
        _postCreator = UserProfile.fromMap(creatorData);
        _singlePost = post;
      } else if (widget.selectedGroupId != null) {
        // Fetch posts for a specific group
        debugPrint('SeePostScreen: Passing group ID to PostService: ${widget.selectedGroupId!}');
        final postsData = await _postService.fetchPostsForGroup(widget.selectedGroupId!);
        _posts = postsData;
      } else if (widget.selectedFriendId != null) {
        // Fetch posts for a specific friend
        debugPrint('SeePostScreen: Passing friend ID to PostService: ${widget.selectedFriendId!}');
        final postsData = await _postService.fetchPostsForFriend(widget.selectedFriendId!);
        _posts = postsData;
      } else {
        setState(() {
          _errorMessage = 'Please select a friend or group to view posts.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      setState(() {
        _errorMessage = 'Failed to load posts. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (widget.postId != null) {
      // Display single post
      if (_singlePost == null || _postCreator == null) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Post Not Found'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: const Center(
            child: Text('The post could not be loaded.'),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: Text('${_postCreator!.firstName}\'s Birthday Post'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9, // Max 90% of screen width
                      maxHeight: 300, // Max height for images
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9, // Common aspect ratio for images
                      child: Builder(
                        builder: (context) {
                          debugPrint('SeePostScreen - Image URL: ${_singlePost!.imageUrl}');
                          final String? accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
                          return _singlePost!.imageUrl != null && _singlePost!.imageUrl!.isNotEmpty
                              ? Image.network(
                                  _singlePost!.imageUrl!,
                                  fit: BoxFit.cover,
                                  headers: accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null,
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('SeePostScreen - Image loading error: $error');
                                    return const Center(
                                      child: Icon(Icons.broken_image,
                                          size: 80, color: Colors.grey),
                                    );
                                  },
                                )
                              : const Center(
                                  child: Icon(Icons.image, size: 80, color: Colors.grey),
                                );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _singlePost!.text,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_singlePost!.userFirstName} ${_singlePost!.userLastName}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4), // Small space between name and date
                      Text(
                        'On: ${_singlePost!.createdAt.toLocal().toString().split(' ')[0]}', // Format date
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'You liked ${_postCreator!.firstName}\'s post!')),
                      );
                    },
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Love this post!'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Display list of posts
      if (_posts.isEmpty) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('No Posts Found'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: const Center(
            child: Text('No posts available for this selection.'),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(
          title: const Text('Posts'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: ListView.builder(
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            final post = _posts[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Center( // Center the image in the list view
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.8, // Max 80% of screen width for list items
                              maxHeight: 250, // Max height for list item images
                            ),
                            child: AspectRatio(
                              aspectRatio: 16 / 9, // Common aspect ratio for images
                              child: Builder(
                                builder: (context) {
                                  debugPrint('SeePostScreen - List Item Image URL: ${post.imageUrl}');
                                  final String? accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
                                  return Image.network(
                                    post.imageUrl!,
                                    fit: BoxFit.cover,
                                    headers: accessToken != null ? {'Authorization': 'Bearer $accessToken'} : null,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('SeePostScreen - List Item Image loading error: $error');
                                      return const Center(
                                        child: Icon(Icons.broken_image,
                                            size: 40, color: Colors.grey),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      post.text,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${post.userFirstName} ${post.userLastName}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4), // Small space between name and date
                          Text(
                            'On: ${post.createdAt.toLocal().toString().split(' ')[0]}', // Format date
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }
}
