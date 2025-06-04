import 'package:flutter/material.dart';
import 'package:birthday_app/models/post.dart';
import 'package:birthday_app/models/user_profile.dart';
import 'package:birthday_app/screens/see_post_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import 'package:birthday_app/services/post_service.dart'; // Import PostService

class HomePostsSection extends StatefulWidget {
  final VoidCallback onBackToAllPosts;
  final String? selectedFriendId;
  final String? selectedGroupId;

  const HomePostsSection({
    super.key,
    required this.onBackToAllPosts,
    this.selectedFriendId,
    this.selectedGroupId,
  });

  @override
  State<HomePostsSection> createState() => _HomePostsSectionState();
}

class _HomePostsSectionState extends State<HomePostsSection> {
  late PostService _postService;
  List<Post> _posts = [];
  bool _isLoadingPosts = true;
  String? _postsError;
  final ScrollController _scrollController = ScrollController();
  bool _hasMore = true;
  bool _isFetchingMore = false;

  @override
  void initState() {
    super.initState();
    _postService = PostService(Supabase.instance.client);
    _fetchPosts(); // Initial fetch
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant HomePostsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedFriendId != oldWidget.selectedFriendId ||
        widget.selectedGroupId != oldWidget.selectedGroupId) {
      _posts.clear(); // Clear existing posts
      _hasMore = true; // Reset hasMore
      _fetchPosts(); // Fetch new posts based on selection
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts({bool isLoadMore = false}) async {
    if (_isFetchingMore || (!_hasMore && isLoadMore)) return;

    setState(() {
      _isLoadingPosts = true;
      _isFetchingMore = isLoadMore;
      _postsError = null;
    });

    try {
      final DateTime? beforeCreatedAt = isLoadMore && _posts.isNotEmpty
          ? DateTime.parse(_posts.last.createdAt.toIso8601String())
          : null;

      final List<Map<String, dynamic>> fetchedData = await _postService.fetchPosts(
        targetFriend: widget.selectedFriendId,
        targetGroup: widget.selectedGroupId,
        beforeCreatedAt: beforeCreatedAt,
        fetchLimit: 20,
      );

      final List<Post> newPosts = fetchedData.map((data) => Post.fromMap(data)).toList();

      setState(() {
        if (isLoadMore) {
          _posts.addAll(newPosts);
        } else {
          _posts = newPosts;
        }
        _hasMore = newPosts.length == 20;
        _isLoadingPosts = false;
        _isFetchingMore = false;
      });
    } catch (e) {
      setState(() {
        _postsError = 'Error fetching posts: $e';
        _isLoadingPosts = false;
        _isFetchingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _hasMore && !_isFetchingMore) {
      _fetchPosts(isLoadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedFriendId == null && widget.selectedGroupId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Select a friend or group to view posts.',
            style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onBackToAllPosts,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to All Posts'),
              ),
            ),
          ),
          _isLoadingPosts && _posts.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _postsError != null
                  ? Center(child: Text(_postsError!))
                  : _posts.isEmpty
                      ? const Center(child: Text('No posts yet. Create one!'))
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _posts.length + (_hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _posts.length) {
                              return const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final post = _posts[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${post.userFirstName} ${post.userLastName}',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      post.createdAt.toLocal().toString().split('.')[0],
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(post.text),
                                    if (post.imageUrl != null) ...[
                                      const SizedBox(height: 8),
                                      Image.network(post.imageUrl!),
                                    ],
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SeePostScreen(postId: post.id),
                                            ),
                                          );
                                        },
                                        child: const Text('View Post'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ],
      );
    }
  }
}
