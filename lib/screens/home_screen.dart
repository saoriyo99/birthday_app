import 'package:flutter/material.dart';
import 'package:birthday_app/screens/birthday_profile_page.dart';
import 'package:birthday_app/screens/add_friend_screen.dart';
import 'package:birthday_app/screens/send_hb_wish_screen.dart';
import 'package:birthday_app/screens/create_post_screen.dart';
import 'package:birthday_app/screens/see_post_screen.dart';
import 'package:birthday_app/screens/group_detail_screen.dart'; // Import GroupDetailScreen
import 'package:birthday_app/models/group.dart'; // Import Group model
import 'package:birthday_app/models/user_profile.dart'; // Import UserProfile model
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/widgets/home_actions_section.dart';
import 'package:birthday_app/widgets/home_groups_section.dart';
import 'package:birthday_app/services/group_service.dart';
import 'package:birthday_app/widgets/home_friends_section.dart';
import 'package:birthday_app/services/friend_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const HomeTabContent(),
    const NotificationsTabContent(),
    const BirthdayProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Birthday App'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddFriendScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();
                // The AuthGate in main.dart will handle navigation after sign out
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error signing out: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}

class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  late GroupService _groupService;
  late FriendService _friendService;

  String? _selectedFriendId;
  String? _selectedGroupId;

  List<Group> _groups = [];
  bool _isLoadingGroups = true;
  String? _groupsError;

  List<Map<String, dynamic>> _friends = [];
  bool _isLoadingFriends = true;
  String? _friendsError;

  @override
  void initState() {
    super.initState();
    _groupService = GroupService(Supabase.instance.client);
    _friendService = FriendService(Supabase.instance.client);
    _fetchAndSetUserGroups();
    _fetchAndSetUserFriends();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchAndSetUserGroups() async {
    setState(() {
      _isLoadingGroups = true;
      _groupsError = null;
    });
    try {
      final groups = await _groupService.fetchUserGroups();
      setState(() {
        _groups = groups;
        _isLoadingGroups = false;
      });
    } catch (e) {
      setState(() {
        _groupsError = 'Error loading groups: $e';
        _isLoadingGroups = false;
      });
    }
  }

  Future<void> _fetchAndSetUserFriends() async {
    setState(() {
      _isLoadingFriends = true;
      _friendsError = null;
    });
    try {
      final friends = await _friendService.fetchUserFriends();
      setState(() {
        _friends = friends;
        _isLoadingFriends = false;
      });
    } catch (e) {
      setState(() {
        _friendsError = 'Error loading friends: $e';
        _isLoadingFriends = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      // Removed controller as HomePostsSection now manages its own scrolling
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const HomeActionsSection(),

            HomeGroupsSection(
              groups: _groups,
              isLoadingGroups: _isLoadingGroups,
              groupsError: _groupsError,
              selectedGroupId: _selectedGroupId,
              onGroupSelected: (groupId) {
                setState(() {
                  _selectedGroupId = groupId;
                  _selectedFriendId = null; // Clear friend selection
                });
              },
              onGroupCreated: _fetchAndSetUserGroups, // Callback to refresh groups
            ),

            HomeFriendsSection(
              friends: _friends,
              isLoadingFriends: _isLoadingFriends,
              friendsError: _friendsError,
              selectedFriendId: _selectedFriendId,
              onFriendSelected: (friendId) {
                setState(() {
                  _selectedFriendId = friendId;
                  _selectedGroupId = null; // Clear group selection
                });
              },
            ),
          ],
        ),
      )
    );
  }
}

class NotificationsTabContent extends StatelessWidget {
  const NotificationsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Updates',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: const Text('See Ben\'s HB post >'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SeePostScreen(
                        postId: 'a_placeholder_post_id', // Replace with actual post ID
                      ),
                    ),
                  );
                },
              ),
            ),
            // Add more notification items here
          ],
        ),
      ),
    );
  }
}
