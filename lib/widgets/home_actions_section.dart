import 'package:flutter/material.dart';
import 'package:birthday_app/screens/invite_user_screen.dart';
import 'package:birthday_app/screens/send_hb_wish_screen.dart';
import 'package:birthday_app/screens/create_post_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeActionsSection extends StatelessWidget {
  const HomeActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }
}
