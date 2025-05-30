import 'package:flutter/material.dart';
import 'package:birthday_app/screens/birthday_profile_page.dart';
import 'package:birthday_app/screens/add_friend_screen.dart';
import 'package:birthday_app/screens/create_group_screen.dart';
import 'package:birthday_app/screens/send_hb_wish_screen.dart';
import 'package:birthday_app/screens/create_post_screen.dart';
import 'package:birthday_app/screens/see_post_screen.dart';
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
        ],
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
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

class HomeTabContent extends StatelessWidget {
  const HomeTabContent({super.key});

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
                        friendName: 'Ben Livio',
                        friendAge: 25,
                        friendBirthday: '05/04/1999',
                        friendGroups: 'NYC, Livio',
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
                    MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
                  );
                },
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              child: ListTile(
                title: const Text('Create HB post'),
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
    final List<String> groups = [
      'Friends #1',
      'Family',
      'Basketball',
      'High School',
      'Yoshimoto',
      'NYC Friends',
      'Olivios',
      'Drop Bears',
      'Opera',
    ];
    return ListView.builder(
      shrinkWrap: true, // Important for nested ListView in SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Disable scrolling for nested ListView
      itemCount: groups.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text(groups[index]),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Tapped on group: ${groups[index]}')),
              );
            },
          ),
        );
      },
    );
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
