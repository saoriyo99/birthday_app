import 'package:flutter/material.dart';
import 'package:birthday_app/screens/signup_screen.dart';
import 'package:birthday_app/screens/home_screen.dart';
import 'package:birthday_app/screens/confirm_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:birthday_app/screens/confirm_invite_screen.dart';
import 'package:birthday_app/screens/confirm_friendship_screen.dart';
import 'package:birthday_app/screens/add_friend_screen.dart'; // Assuming this is needed for deep links
import 'package:birthday_app/screens/group_detail_screen.dart'; // Assuming this is needed for deep links

const supabaseUrl = 'https://aehxjavawqtppxqcqwfw.supabase.co';
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const MyApp());
}

class AppRouter {
  static Future<String> getInitialRoute() async {
    final appLinks = AppLinks();
    final initialLink = await appLinks.getInitialAppLink();

    if (initialLink != null) {
      final route = _parseDeepLinkRoute(initialLink);
      if (route != null) {
        return route;
      }
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Check user profile and navigate if needed, otherwise go to home
      final supabase = Supabase.instance.client;
      try {
        final response = await supabase
            .schema('social')
            .from('users')
            .select('id')
            .eq('id', user.id)
            .limit(1)
            .maybeSingle();

        if (response == null) {
          return '/confirm-profile';
        } else {
          return '/home';
        }
      } catch (error) {
        debugPrint('Error checking user profile in AppRouter: $error');
        return '/signup'; // Fallback to signup on error
      }
    } else {
      return '/signup';
    }
  }

  static String? _parseDeepLinkRoute(Uri link) {
    Uri? effectiveUri;
    if (link.fragment.isNotEmpty) {
      try {
        effectiveUri = Uri.parse(link.fragment);
      } catch (e) {
        debugPrint('Error parsing URI fragment in AppRouter: $e');
        effectiveUri = link;
      }
    } else {
      effectiveUri = link;
    }

    if (effectiveUri != null) {
      if (effectiveUri.path == '/joingroup' && effectiveUri.queryParameters.containsKey('code')) {
        final inviteCode = effectiveUri.queryParameters['code'];
        if (inviteCode != null) {
          return '/confirm-invite?code=$inviteCode';
        }
      } else if (effectiveUri.path == '/addfriend' && effectiveUri.queryParameters.containsKey('userId')) {
        final friendId = effectiveUri.queryParameters['userId'];
        if (friendId != null) {
          return '/confirm-friendship?userId=$friendId';
        }
      }
    }
    return null; // If no specific deep link, let auth state determine route
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: AppRouter.getInitialRoute(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            home: Scaffold(body: Container()), // Blank while loading
          );
        }

        return MaterialApp(
          title: 'Birthday App',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          initialRoute: snapshot.data,
          routes: {
            '/home': (context) => const HomeScreen(),
            '/signup': (context) => const SignUpScreen(),
            '/confirm-profile': (context) => ConfirmProfileScreen(
                  initialName: Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? '',
                  initialEmail: Supabase.instance.client.auth.currentUser?.email ?? '',
                  userId: Supabase.instance.client.auth.currentUser!.id,
                ),
            '/confirm-invite': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
              final inviteCode = args?['code'];
              return ConfirmInviteScreen(inviteCode: inviteCode!);
            },
            '/confirm-friendship': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>?;
              final friendId = args?['userId'];
              return ConfirmFriendshipScreen(friendId: friendId!);
            },
            // Add other routes as needed
          },
        );
      },
    );
  }
}
