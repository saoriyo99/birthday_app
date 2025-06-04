import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/services/friend_service.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:birthday_app/app_router_delegate.dart'; // Import AppRouterDelegate
import 'package:birthday_app/app_route_path.dart'; // Import AppRoutePath

class HomeFriendsSection extends StatefulWidget {
  final Function(String?) onFriendSelected;
  final List<Map<String, dynamic>> friends;
  final bool isLoadingFriends;
  final String? friendsError;
  final String? selectedFriendId;

  const HomeFriendsSection({
    super.key,
    required this.onFriendSelected,
    required this.friends,
    required this.isLoadingFriends,
    this.friendsError,
    this.selectedFriendId,
  });

  @override
  State<HomeFriendsSection> createState() => _HomeFriendsSectionState();
}

class _HomeFriendsSectionState extends State<HomeFriendsSection> {
  late FriendService _friendService;

  @override
  void initState() {
    super.initState();
    _friendService = FriendService(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Friends',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        _buildFriendList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFriendList() {
    if (widget.isLoadingFriends) {
      return const Center(child: CircularProgressIndicator());
    } else if (widget.friendsError != null) {
      return Center(child: Text(widget.friendsError!));
    } else if (widget.friends.isEmpty) {
      return const Center(child: Text('No friends found. Add some!'));
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.friends.length,
        itemBuilder: (context, index) {
          final friend = widget.friends[index];
          final friendName = friend['username'] ?? '${friend['first_name']} ${friend['last_name']}';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            color: widget.selectedFriendId == friend['id'] ? Theme.of(context).colorScheme.secondaryContainer : null,
            child: ListTile(
              title: Text(friendName),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                final friendId = friend['id'];
                debugPrint('Friend ID clicked: $friendId');
                // Navigate to SeePostScreen with selected friend ID
                final delegate = Router.of(context).routerDelegate as AppRouterDelegate;
                delegate.setNewRoutePath(AppRoutePath.postsByFriend(friendId));
                widget.onFriendSelected(friendId); // Call the callback to update parent state
              },
            ),
          );
        },
      );
    }
  }
}
