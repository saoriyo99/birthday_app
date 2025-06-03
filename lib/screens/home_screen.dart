import 'package:flutter/material.dart';
import 'package:birthday_app/screens/birthday_profile_page.dart';
import 'package:birthday_app/screens/add_friend_screen.dart';
import 'package:birthday_app/screens/send_hb_wish_screen.dart';
import 'package:birthday_app/screens/create_post_screen.dart';
import 'package:birthday_app/screens/see_post_screen.dart';
import 'package:birthday_app/screens/group_detail_screen.dart'; // Import GroupDetailScreen
import 'package:birthday_app/models/group.dart'; // Import Group model
// import 'package:birthday_app/models/friendship.dart'; // No longer needed as we use a direct SQL function
import 'package:birthday_app/models/user_profile.dart'; // Import UserProfile model
import 'package:supabase_flutter/supabase_flutter.dart';

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
  List<Map<String, dynamic>> _groups = [];
  bool _isLoadingGroups = true;
  String? _groupsError;

  List<Map<String, dynamic>> _friends = [];
  bool _isLoadingFriends = true;
  String? _friendsError;

  @override
  void initState() {
    super.initState();
    _fetchAndSetUserGroups();
    _fetchAndSetUserFriends(); // Fetch friends as well
  }

  Future<void> _fetchAndSetUserGroups() async {
    try {
      final groups = await _fetchUserGroups();
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

  Future<List<Map<String, dynamic>>> _fetchUserGroups() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return [];
    }
    try {
      // Get group memberships for current user
      final groupMemberships = await Supabase.instance.client
          .schema('social')
          .from('group_members')
          .select('group_id')
          .eq('user_id', currentUser.id);

      if (groupMemberships == null) {
        throw Exception('Failed to fetch group memberships');
      }

      final groupIds = groupMemberships
          .map((e) => e['group_id'] as String)
          .toList();

      if (groupIds.isEmpty) {
        return [];
      }

      // Query groups by groupIds, and also fetch their members
      final groupsResponse = await Supabase.instance.client
          .schema('social')
          .from('groups')
          .select('id, name, created_at, type, end_date, group_members(id, group_id, user_id, joined_at, users(first_name, last_name))') // Select group_members and nested user data
          .inFilter('id', groupIds);

      if (groupsResponse == null) {
        throw Exception('Failed to fetch groups');
      }

      return groupsResponse.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch user groups: $e');
    }
  }

  Future<void> _fetchAndSetUserFriends() async {
    try {
      final friends = await _fetchUserFriends();
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

  Future<List<Map<String, dynamic>>> _fetchUserFriends() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return [];
    }
    try {
      final friendsResponse = await Supabase.instance.client
          .schema('social')
          .rpc('get_user_friends', params: {'target_user_id': currentUser.id});

      if (friendsResponse == null) {
        throw Exception('Failed to fetch friends');
      }

      return friendsResponse.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to fetch user friends: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Actions Section
            Text(
              'Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: const Text('Send Ben HB!'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SendHbWishScreen(
                        friendName: 'Ben Lirio',
                        friendAge: 25,
                        friendBirthday: '05/04/1999',
                        friendGroups: 'NYC, Lirio',
                      ),
                    ),
                  );
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: const Text('Create Group'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddFriendScreen(initialModeIsGroup: true)),
                  );
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: const Text('Create Post'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreatePostScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                try {
                  final List<Map<String, dynamic>> response = await Supabase.instance.client.schema('social').from('users').select().limit(1);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Supabase Ping Success: $response')),
                  );
                  print('Supabase Ping Success: $response');
                } on PostgrestException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Supabase Ping Error: ${e.message}')),
                  );
                  print('Supabase Ping Error: ${e.message}');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Supabase Ping Exception: $e')),
                  );
                  print('Supabase Ping Exception: $e');
                }
              },
              child: const Text('Ping Supabase'),
            ),
            const SizedBox(height: 24),

            // Groups Section
            Text(
              'Groups',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            _buildGroupList(),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    String groupName = '';
                    String groupType = 'Family';
                    DateTime? endDate;

                    return AlertDialog(
                      title: const Text('Create Group'),
                      content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Group Name',
                                  ),
                                  onChanged: (value) {
                                    groupName = value;
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: groupType,
                                  decoration: const InputDecoration(
                                    labelText: 'Group Type',
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: 'Family', child: Text('Family')),
                                    DropdownMenuItem(value: 'Friends', child: Text('Friends')),
                                    DropdownMenuItem(value: 'Work', child: Text('Work')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        groupType = value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                InputDatePickerFormField(
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2100),
                                  fieldLabelText: 'End Date (optional)',
                                  onDateSubmitted: (date) {
                                    endDate = date;
                                  },
                                  onDateSaved: (date) {
                                    endDate = date;
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                          ElevatedButton(
                            onPressed: () async {
                              if (groupName.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Group name cannot be empty')),
                                );
                                return;
                              }
                              try {
                                final response = await Supabase.instance.client
                                    .schema('social')
                                    .from('groups')
                                    .insert({
                                      'name': groupName,
                                      'type': groupType,
                                      'end_date': endDate?.toIso8601String(),
                                    })
                                    .select()
                                    .single();

                                // After creating the group, add the current user as a group member
                                final currentUser = Supabase.instance.client.auth.currentUser;
                                if (currentUser != null) {
                                  await Supabase.instance.client
                                      .schema('social')
                                      .from('group_members')
                                      .insert({
                                        'group_id': response['id'],
                                        'user_id': currentUser.id,
                                      });
                                }

                                // Add the new group to the local list and update the UI
                                setState(() {
                                  _groups.add(response);
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Group "$groupName" of type "$groupType" created and you were added as a member')),
                                );
                                Navigator.of(context).pop();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Exception creating group: $e')),
                                );
                              }
                            },
                            child: const Text('Create'),
                          ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Create Group'),
            ),
            const SizedBox(height: 24),

            // Friends Section
            Text(
              'Friends',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            _buildFriendList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupList() {
    if (_isLoadingGroups) {
      return const Center(child: CircularProgressIndicator());
    } else if (_groupsError != null) {
      return Center(child: Text(_groupsError!));
    } else if (_groups.isEmpty) {
      return const Center(child: Text('No groups found'));
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final groupMap = _groups[index];
          final group = Group.fromMap(groupMap); // Convert map to Group object
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              title: Text(group.name),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupDetailScreen(group: group),
                  ),
                );
              },
            ),
          );
        },
      );
    }
  }

  Widget _buildFriendList() {
    if (_isLoadingFriends) {
      return const Center(child: CircularProgressIndicator());
    } else if (_friendsError != null) {
      return Center(child: Text(_friendsError!));
    } else if (_friends.isEmpty) {
      return const Center(child: Text('No friends found. Add some!'));
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friend = _friends[index];
          final friendName = friend['username'] ?? '${friend['first_name']} ${friend['last_name']}';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              title: Text(friendName),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Navigate to friend's profile or send HB wish
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tapped on friend: $friendName')),
                );
              },
            ),
          );
        },
      );
    }
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
                        userName: 'Ben Livio',
                        postPhotoUrl: 'placeholder_url', // Replace with actual URL
                        postText: 'Had a great birthday thanks to everyone!',
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
