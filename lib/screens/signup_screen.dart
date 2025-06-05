import 'package:flutter/material.dart';
import 'package:birthday_app/screens/home_screen.dart';
import 'package:birthday_app/screens/confirm_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:birthday_app/constants/urls.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  // Removed GoogleSignIn instance as we will use Supabase's signInWithOAuth directly.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  height: 24.0,
                  width: 24.0,
                ),
                label: const Text(
                  'Sign in with Google',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      final supabase = Supabase.instance.client;
      // Use Supabase's signInWithOAuth directly for Google
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: baseAppUrl, // This should match your deep link configuration
      );

      // Supabase's signInWithOAuth handles redirection and session creation.
      // The rest of the logic will be handled by Supabase's auth listener,
      // which should be set up in main.dart or a wrapper widget.
      // For now, we'll assume the user will be redirected by the OAuth flow.
      // The check for new/existing user will happen after the OAuth flow completes
      // and the session is established.

      // Since signInWithOAuth redirects, the code below this point might not execute immediately.
      // The user will be redirected back to the app, and the auth listener will pick up the session.
      // For a complete flow, you'd typically have an AuthState listener in your main app widget
      // that navigates based on the session state.

      // For demonstration, let's add a temporary check here, though in a real app,
      // this would be part of an auth listener.
      // This part will only execute if signInWithOAuth does not cause a full page redirect
      // or if it's called in a context where it doesn't immediately exit.
      // Given the nature of web OAuth, a full redirect is expected.
      // So, the logic for checking new/existing user should ideally be in a redirect handler
      // or an auth state listener.

      // For now, let's keep the existing user check logic here, assuming
      // the OAuth flow might not always cause a full app restart/redirect
      // in all Flutter web environments or for future changes.
      // However, the primary way to handle this is via an AuthState listener.

      // The user check and navigation logic is now handled by AuthGate in main.dart
      // after the OAuth flow completes and the auth state changes.
    } catch (error) {
      debugPrint('Error during Google Sign-In with Supabase OAuth: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectableText('Error signing in with Google: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Controllers for name and birthday are removed, so no need to dispose them.
    super.dispose();
  }
}
