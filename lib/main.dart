import 'package:flutter/material.dart';
import 'package:birthday_app/screens/signup_screen.dart';
import 'package:birthday_app/screens/home_screen.dart';
import 'package:birthday_app/screens/confirm_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
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
