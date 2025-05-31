import 'package:flutter/material.dart';
import 'package:birthday_app/screens/signup_screen.dart';
import 'package:birthday_app/screens/home_screen.dart';
import 'package:birthday_app/screens/confirm_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:birthday_app/screens/confirm_friendship_screen.dart'; // Import the new screen

const supabaseUrl = 'https://aehxjavawqtppxqcqwfw.supabase.co';
const supabaseKey = String.fromEnvironment('SUPABASE_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  runApp(const MyApp());
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
      home: const AuthGate(), // Use AuthGate for initial routing
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _appLinksSubscription;
  String? _pendingInviteCode; // Store invite code until user is signed in

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _checkUserProfileAndNavigate(session.user!);
      } else if (event == AuthChangeEvent.signedOut) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignUpScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _appLinksSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Get the initial link
    final appLink = await _appLinks.getInitialAppLink();
    if (appLink != null) {
      _handleIncomingLink(appLink);
    }

    // Handle incoming links while the app is running
    _appLinksSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    });
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    // For web, the path might be in the fragment (after #)
    // For mobile, it might be in the path directly
    Uri? effectiveUri;
    if (uri.fragment.isNotEmpty) {
      try {
        effectiveUri = Uri.parse(uri.fragment);
      } catch (e) {
        debugPrint('Error parsing URI fragment: $e');
        effectiveUri = uri; // Fallback to original URI if fragment is not a valid URI
      }
    } else {
      effectiveUri = uri;
    }

    if (effectiveUri != null && effectiveUri.path == '/invite' && effectiveUri.queryParameters.containsKey('code')) {
      final inviteCode = effectiveUri.queryParameters['code'];
      debugPrint('Received invite code: $inviteCode');

      if (inviteCode != null) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // User is already signed in, fetch inviter info and navigate to confirmation
          await _navigateToConfirmFriendship(inviteCode);
        } else {
          // User not signed in, store code and navigate to confirmation after sign-in
          _pendingInviteCode = inviteCode;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite link detected. Please sign in to accept.')),
          );
        }
      }
    }
  }

  Future<void> _navigateToConfirmFriendship(String inviteCode) async {
    final supabase = Supabase.instance.client;
    try {
      // Look up the invite to get inviter_id
      final List<Map<String, dynamic>> invites = await supabase
          .schema('social')
          .from('invites')
          .select('id, inviter_id, used')
          .eq('invite_code', inviteCode)
          .limit(1);

      if (invites.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid invite code.')),
        );
        return;
      }

      final invite = invites.first;
      if (invite['used'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This invite has already been used.')),
        );
        return;
      }

      final inviterId = invite['inviter_id'];
      if (inviterId == supabase.auth.currentUser?.id) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot accept your own invite.')),
        );
        return;
      }

      // Fetch inviter's name from social.users
      final inviterProfile = await supabase
          .schema('social')
          .from('users')
          .select('first_name, last_name')
          .eq('id', inviterId)
          .limit(1)
          .maybeSingle();

      if (inviterProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inviter profile not found.')),
        );
        return;
      }

      final inviterName = '${inviterProfile['first_name']} ${inviterProfile['last_name']}';

      // Navigate to ConfirmFriendshipScreen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ConfirmFriendshipScreen(
            inviteCode: inviteCode,
            inviterId: inviterId,
            inviterName: inviterName,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to confirm friendship: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing invite: ${e.toString()}')),
      );
    }
  }

  Future<void> _checkUserProfileAndNavigate(User user) async {
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
        // User not found in social.users, navigate to ConfirmProfileScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ConfirmProfileScreen(
              initialName: user.userMetadata?['full_name'] ?? '',
              initialEmail: user.email ?? '',
              userId: user.id,
            ),
          ),
          (route) => false,
        );
      } else {
        // User found in social.users, navigate to HomeScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        // If there's a pending invite, process it now that user is signed in
        if (_pendingInviteCode != null) {
          await _navigateToConfirmFriendship(_pendingInviteCode!);
          _pendingInviteCode = null; // Clear after use
        }
      }
    } catch (error) {
      debugPrint('Error checking user profile: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking user profile: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      // Fallback to SignUpScreen on error
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignUpScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initial check when the app starts
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _checkUserProfileAndNavigate(user);
      // Show a loading indicator while checking
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    } else {
      // No user signed in, show SignUpScreen
      return const SignUpScreen();
    }
  }
}
