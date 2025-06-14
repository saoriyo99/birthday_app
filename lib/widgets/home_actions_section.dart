import 'package:flutter/material.dart';
import 'package:birthday_app/screens/invite_user_screen.dart';
import 'package:birthday_app/screens/user_profile_page.dart'; // Import UserProfilePage
import 'package:birthday_app/screens/create_post_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:birthday_app/models/user_profile.dart'; // Import UserProfile

class HomeActionsSection extends StatelessWidget {
  const HomeActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a dummy UserProfile for Ben Lirio
    final benLirioProfile = UserProfile(
      id: 'ben-lirio-id', // Dummy ID
      firstName: 'Ben',
      lastName: 'Lirio',
      birthday: DateTime(1999, 5, 4), // Parse from '05/04/1999'
      createdAt: DateTime.now(), // Dummy createdAt
      groups: 'NYC, Lirio',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
                  builder: (context) => UserProfilePage(userProfile: benLirioProfile),
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
                MaterialPageRoute(builder: (context) => const InviteUserScreen(initialModeIsGroup: true)),
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
      ],
    );
  }
}
