import 'package:flutter/material.dart';
import 'package:birthday_app/screens/user_profile_page.dart';
import 'package:birthday_app/screens/invite_user_screen.dart';
import 'package:birthday_app/screens/create_post_screen.dart';
import 'package:birthday_app/app_router_delegate.dart'; // Import AppRouterDelegate
import 'package:birthday_app/app_route_path.dart'; // Import AppRoutePath
import 'package:birthday_app/models/friend.dart'; //Import Friend model
import 'package:birthday_app/models/group.dart'; // Import Group model
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/widgets/home_actions_section.dart';
import 'package:birthday_app/widgets/home_groups_section.dart';
import 'package:birthday_app/services/group_service.dart';
import 'package:birthday_app/widgets/home_friends_section.dart';
import 'package:birthday_app/services/friend_service.dart';
import 'package:birthday_app/services/notification_service.dart';
import 'package:birthday_app/models/notification.dart';

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
    const UserProfilePage(),
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
                MaterialPageRoute(builder: (context) => const InviteUserScreen()),
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

  List<Friend> _friends = [];
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

class NotificationsTabContent extends StatefulWidget {
  const NotificationsTabContent({super.key});

  @override
  State<NotificationsTabContent> createState() => _NotificationsTabContentState();
}

class _NotificationsTabContentState extends State<NotificationsTabContent> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NotificationService _notificationService;
  List<UserNotification> _allNotifications = [];
  List<UserNotification> _actionNotifications = [];
  List<UserNotification> _updateNotifications = [];
  bool _isLoadingNotifications = true;
  String? _notificationsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _notificationService = NotificationService(Supabase.instance.client);
    _fetchAndSetUserNotifications();
  }

  @override
  void dispose() {
    // Mark all currently unread notifications as read when leaving the screen
    for (var notification in _allNotifications) {
      if (!notification.isRead) {
        _notificationService.markNotificationAsRead(notification.id);
      }
    }
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndSetUserNotifications() async {
    setState(() {
      _isLoadingNotifications = true;
      _notificationsError = null;
    });
    try {
      final notifications = await _notificationService.fetchUserNotifications();
      setState(() {
        _allNotifications = notifications;
        _actionNotifications = notifications.where((n) => n.actionRequired).toList();
        _updateNotifications = notifications.where((n) => !n.actionRequired).toList();
        _isLoadingNotifications = false;
      });
    } catch (e) {
      setState(() {
        _notificationsError = 'Error loading notifications: $e';
        _isLoadingNotifications = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Actions'),
            Tab(text: 'Updates'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(_actionNotifications, _isLoadingNotifications, _notificationsError),
              _buildNotificationList(_updateNotifications, _isLoadingNotifications, _notificationsError),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationList(List<UserNotification> notifications, bool isLoading, String? error) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (error != null) {
      return Center(child: SelectableText(error));
    } else if (notifications.isEmpty) {
      return const Center(child: Text('No notifications to display.'));
    } else {
      return ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
            child: ListTile(
              title: Text(
                notification.content,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(notification.type),
              onTap: () async {
                if (!notification.isRead) {
                  await _notificationService.markNotificationAsRead(notification.id);
                  await _fetchAndSetUserNotifications(); // Refresh notifications after marking as read
                }

                final appRouterDelegate = Router.of(context).routerDelegate as AppRouterDelegate;

                if (notification.type == 'birthday') {
                  appRouterDelegate.setNewRoutePath(AppRoutePath.sendHbWish(notification.sourceId));
                } else if (notification.type == 'birthday_post') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tapped on: ${notification.content}')),
                  );
                }
              },
            ),
          );
        },
      );
    }
  }

  Widget _buildFriendList() {
    final List<String> friends = [
      'Ben Livio',
      'Jani Yoshimoto',
      'Tamera Sims',
      'Sidney Tanioka',
    ];
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(friends[index]),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tapped on friend: ${friends[index]}')),
              );
            },
          ),
        );
      },
    );
  }
}
