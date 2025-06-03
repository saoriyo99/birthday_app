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

  // The initial route is now handled within MyApp's initState
  runApp(const MyApp());
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

    final pathSegments = effectiveUri.pathSegments;

    if (pathSegments.isNotEmpty) {
      final lastSegment = pathSegments.last;

      if (lastSegment == 'joingroup' && effectiveUri.queryParameters.containsKey('code')) {
        final inviteCode = effectiveUri.queryParameters['code'];
        return InitialRouteResult('/confirm-invite', {'code': inviteCode!});
      } else if (lastSegment == 'addfriend' && effectiveUri.queryParameters.containsKey('userId')) {
        final friendId = effectiveUri.queryParameters['userId'];
        return InitialRouteResult('/confirm-friendship', {'userId': friendId!});
      } else if (lastSegment == 'invite' && effectiveUri.queryParameters.containsKey('code')) {
        final inviteCode = effectiveUri.queryParameters['code'];
        return InitialRouteResult('/confirm-invite', {'code': inviteCode!});
      }
    }

    return null;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _handleInitialLink();
    _setupLiveLinkListener();
  }

  Future<void> _handleInitialLink() async {
    final appLinks = AppLinks();
    final initialLink = await appLinks.getInitialAppLink();

    if (initialLink != null) {
      _handleLink(initialLink);
    }
  }

  void _setupLiveLinkListener() {
    final appLinks = AppLinks();
    _linkSubscription = appLinks.uriLinkStream.listen((Uri? link) {
      if (link != null) {
        _handleLink(link);
      }
    });
  }

  void _handleLink(Uri link) {
    final routeResult = AppRouter._parseDeepLinkRoute(link);
    if (routeResult != null) {
      if (routeResult.route == '/confirm-invite') {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ConfirmInviteScreen(inviteCode: routeResult.arguments!['code']!)));
      } else if (routeResult.route == '/confirm-friendship') {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ConfirmFriendshipScreen(friendId: routeResult.arguments!['userId']!)));
      }
    }
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
      home: HomeScreen(),  // Always start here
    );
  }
}
