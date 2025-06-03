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

class InitialRouteResult {
  final String route;
  final Map<String, String>? arguments;

  InitialRouteResult(this.route, [this.arguments]);
}

class AppRouter {
  static Future<InitialRouteResult> getInitialRoute() async {
    final appLinks = AppLinks();
    final initialLink = await appLinks.getInitialAppLink();

    if (initialLink != null) {
      final result = _parseDeepLinkRoute(initialLink);
      if (result != null) {
        return result;
      }
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
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
          return InitialRouteResult('/confirm-profile');
        } else {
          return InitialRouteResult('/home');
        }
      } catch (error) {
        debugPrint('Error checking user profile in AppRouter: $error');
        return InitialRouteResult('/signup');
      }
    } else {
      return InitialRouteResult('/signup');
    }
  }

  static InitialRouteResult? _parseDeepLinkRoute(Uri link) {
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
          return InitialRouteResult('/confirm-invite', {'code': inviteCode});
        }
      } else if (effectiveUri.path == '/addfriend' && effectiveUri.queryParameters.containsKey('userId')) {
        final friendId = effectiveUri.queryParameters['userId'];
        if (friendId != null) {
          return InitialRouteResult('/confirm-friendship', {'userId': friendId});
        }
      }
    }
    return null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birthday App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/confirm-profile': (context) {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacementNamed('/signup');
            });
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return ConfirmProfileScreen(
            initialName: user.userMetadata?['full_name'] ?? '',
            initialEmail: user.email ?? '',
            userId: user.id,
          );
        },
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
      },
      home: const SplashScreen(), // simple loading screen while we resolve route
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initRouting();
  }

  Future<void> _initRouting() async {
    final routeResult = await AppRouter.getInitialRoute();

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      routeResult.route,
      arguments: routeResult.arguments,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
