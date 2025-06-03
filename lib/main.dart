import 'package:flutter/material.dart';
import 'package:birthday_app/screens/signup_screen.dart';
import 'package:birthday_app/screens/home_screen.dart';
import 'package:birthday_app/screens/confirm_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'package:birthday_app/screens/confirm_invite_screen.dart';
import 'package:birthday_app/screens/confirm_friendship_screen.dart';
import 'package:birthday_app/screens/add_friend_screen.dart';
import 'package:birthday_app/screens/group_detail_screen.dart';
import 'dart:async';

// Replace with your own keys
const supabaseUrl = 'https://aehxjavawqtppxqcqwfw.supabase.co';
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appLinks = AppLinks();
  final initialLink = await appLinks.getInitialAppLink();

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);

  final routeResult = await AppRouter.getInitialRoute(initialLink);

  runApp(MyApp(routeResult: routeResult));
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

    // Normalize path
    final pathSegments = effectiveUri.pathSegments;

    if (pathSegments.isNotEmpty) {
      final lastSegment = pathSegments.last;

      if (lastSegment == 'joingroup' && effectiveUri.queryParameters.containsKey('code')) {
        final inviteCode = effectiveUri.queryParameters['code'];
        if (inviteCode != null) {
          return InitialRouteResult('/confirm-invite', {'code': inviteCode});
        }
      } else if (lastSegment == 'addfriend' && effectiveUri.queryParameters.containsKey('userId')) {
        final friendId = effectiveUri.queryParameters['userId'];
        if (friendId != null) {
          return InitialRouteResult('/confirm-friendship', {'userId': friendId});
        }
      }
    }

    return null;
  }
}

class MyApp extends StatefulWidget {
  final InitialRouteResult routeResult;

  const MyApp({super.key, required this.routeResult});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _setupLiveDeepLinkListener();
  }

  void _setupLiveDeepLinkListener() {
    final appLinks = AppLinks();
    _linkSubscription = appLinks.uriLinkStream.listen((Uri? link) async {
      if (link != null) {
        final routeResult = AppRouter._parseDeepLinkRoute(link);
        if (routeResult != null && mounted) {
          // Navigate live after app has started
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AppRouterWidget(routeResult: routeResult),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Birthday App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AppRouterWidget(routeResult: widget.routeResult),
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
          return MaterialPageRoute(builder: (_) => const SignUpScreen());
        }
      },
    );
  }
}

class AppRouterWidget extends StatelessWidget {
  final InitialRouteResult routeResult;

  const AppRouterWidget({super.key, required this.routeResult});

  @override
  Widget build(BuildContext context) {
    switch (routeResult.route) {
      case '/home':
        return const HomeScreen();
      case '/signup':
        return const SignUpScreen();
      case '/confirm-profile':
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          return const SignUpScreen();
        }
        return ConfirmProfileScreen(
          initialName: user.userMetadata?['full_name'] ?? '',
          initialEmail: user.email ?? '',
          userId: user.id,
        );
      case '/confirm-invite':
        final inviteCode = routeResult.arguments?['code'];
        return ConfirmInviteScreen(inviteCode: inviteCode!);
      case '/confirm-friendship':
        final friendId = routeResult.arguments?['userId'];
        return ConfirmFriendshipScreen(friendId: friendId!);
      default:
        return const SignUpScreen();
    }
  }
}
