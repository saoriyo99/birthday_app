import 'package:flutter/material.dart';
import 'package:birthday_app/screens/signup_screen.dart';
import 'package:birthday_app/screens/home_screen.dart';
import 'package:birthday_app/screens/confirm_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

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
  String? _initialInviteCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _checkUserProfileAndNavigate(session.user!, inviteCode: _initialInviteCode);
        _initialInviteCode = null; // Clear after use
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

  void _handleIncomingLink(Uri uri) {
    if (uri.path == '/invite' && uri.queryParameters.containsKey('code')) {
      final inviteCode = uri.queryParameters['code'];
      debugPrint('Received invite code: $inviteCode');
      if (inviteCode != null) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          // User is already signed in, process invite immediately
          _processInviteAcceptance(inviteCode, user.id);
        } else {
          // User not signed in, store code and process after sign-in
          _initialInviteCode = inviteCode;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invite link detected. Please sign in to accept.')),
          );
        }
      }
    }
  }

  Future<void> _checkUserProfileAndNavigate(User user, {String? inviteCode}) async {
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
        if (inviteCode != null) {
          _processInviteAcceptance(inviteCode, user.id);
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

  Future<void> _processInviteAcceptance(String inviteCode, String recipientId) async {
    final supabase = Supabase.instance.client;
    try {
      // 1. Look up the invite and verify
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
      if (inviterId == recipientId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot accept your own invite.')),
        );
        return;
      }

      // 2. Mark invite as used
      await supabase.schema('social').from('invites').update({
        'used': true,
        'used_by': recipientId,
        'used_at': DateTime.now().toIso8601String(),
      }).eq('id', invite['id']);

      // 3. Automatically create a friendship (bidirectional)
      await supabase.schema('social').from('friendships').insert([
        {'user_1_id': inviterId, 'user_2_id': recipientId, 'status': 'accepted'},
        {'user_1_id': recipientId, 'user_2_id': inviterId, 'status': 'accepted'}, // For bidirectional friendship
      ]);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friendship established!')),
      );
    } catch (e) {
      debugPrint('Error processing invite: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting invite: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initial check when the app starts
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _checkUserProfileAndNavigate(user, inviteCode: _initialInviteCode);
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
