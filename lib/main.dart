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

  // Get deep link BEFORE Supabase init
  final appLinks = AppLinks();
  final initialLink = await appLinks.getInitialAppLink();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  
  runApp(MyApp(initialLink: initialLink));
}

class InitialRouteResult {
  final String route;
  final Map<String, String>? arguments;

  InitialRouteResult(this.route, [this.arguments]);
}

class AppRouter {
  static Future<InitialRouteResult> getInitialRoute(Uri? initialLink) async {
    if (initialLink != null) {
      final result = _parseDeepLinkRoute(initialLink);
      if (result != null) return result;
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
  final Uri? initialLink;

  const MyApp({super.key, required this.initialLink});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birthday App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(initialLink: initialLink),
      onGenerateRoute: (settings) {
        final name = settings.name;
        final args = settings.arguments as Map<String, String>?;

        if (name == '/home') {
          return MaterialPageRoute(builder: (_) => const HomeScreen());
        } else if (name == '/signup') {
          return MaterialPageRoute(builder: (_) => const SignUpScreen());
        } else if (name == '/confirm-profile') {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) {
            return MaterialPageRoute(builder: (_) => const SignUpScreen());
          }
          return MaterialPageRoute(
            builder: (_) => ConfirmProfileScreen(
              initialName: user.userMetadata?['full_name'] ?? '',
              initialEmail: user.email ?? '',
              userId: user.id,
            ),
          );
        } else if (name == '/confirm-invite') {
          final inviteCode = args?['code'];
          return MaterialPageRoute(
            builder: (_) => ConfirmInviteScreen(inviteCode: inviteCode!),
          );
        } else if (name == '/confirm-friendship') {
          final friendId = args?['userId'];
          return MaterialPageRoute(
            builder: (_) => ConfirmFriendshipScreen(friendId: friendId!),
          );
        } else {
          // fallback route
          return MaterialPageRoute(builder: (_) => const SignUpScreen());
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  final Uri? initialLink;

  const SplashScreen({super.key, required this.initialLink});

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
    final routeResult = await AppRouter.getInitialRoute(widget.initialLink);

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
