import 'package:flutter/material.dart';
import 'package:birthday_app/app_route_path.dart';
import 'package:birthday_app/screens/home_screen.dart';
import 'package:birthday_app/screens/confirm_invite_screen.dart';
import 'package:birthday_app/screens/confirm_friendship_screen.dart';
import 'package:birthday_app/screens/signup_screen.dart';
import 'package:birthday_app/screens/confirm_profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
  final GlobalKey<NavigatorState> navigatorKey;

  AppRoutePath? _currentPath;
  bool _loggedIn;
  bool _isProfileConfirmed;

  AppRouterDelegate()
      : navigatorKey = GlobalKey<NavigatorState>(),
        _loggedIn = Supabase.instance.client.auth.currentUser != null,
        _isProfileConfirmed = false {
    _initAuthListener();
    _checkProfileConfirmation().then((_) => notifyListeners()); // Initial check
  }

  void _initAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        _loggedIn = session != null;
        if (_loggedIn) {
          await _checkProfileConfirmation();
        } else {
          _isProfileConfirmed = false;
        }
      } else if (event == AuthChangeEvent.signedOut) {
        _loggedIn = false;
        _isProfileConfirmed = false;
      }
      notifyListeners();
    });
  }

  Future<void> _checkProfileConfirmation() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final response = await Supabase.instance.client
            .schema('social')
            .from('users')
            .select('id')
            .eq('id', user.id)
            .limit(1)
            .maybeSingle();
        _isProfileConfirmed = response != null;
      } catch (e) {
        debugPrint('Error checking profile confirmation: $e');
        _isProfileConfirmed = false;
      }
    } else {
      _isProfileConfirmed = false;
    }
  }

  @override
  AppRoutePath? get currentConfiguration {
    if (!_loggedIn) {
      return AppRoutePath.signUp();
    }
    if (!_isProfileConfirmed) {
      return AppRoutePath.confirmProfile();
    }
    return _currentPath ?? AppRoutePath.home();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) {
      return Navigator(
        key: navigatorKey,
        pages: [
          MaterialPage(child: SignUpScreen()),
        ],
        onPopPage: (route, result) => route.didPop(result),
      );
    }

    if (!_isProfileConfirmed) {
      return Navigator(
        key: navigatorKey,
        pages: [
          MaterialPage(
              child: ConfirmProfileScreen(
                initialName: Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? '',
                initialEmail: Supabase.instance.client.auth.currentUser?.email ?? '',
                userId: Supabase.instance.client.auth.currentUser?.id ?? '',
              )),
        ],
        onPopPage: (route, result) => route.didPop(result),
      );
    }

    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(child: HomeScreen()),

        if (_currentPath?.inviteCode != null)
          MaterialPage(
              child: ConfirmInviteScreen(inviteCode: _currentPath!.inviteCode!)),

        if (_currentPath?.friendId != null)
          MaterialPage(
              child: ConfirmFriendshipScreen(friendId: _currentPath!.friendId!)),
      ],
      onPopPage: (route, result) => route.didPop(result),
    );
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    _currentPath = configuration;
    await _checkProfileConfirmation(); // Ensure profile status is up-to-date
    notifyListeners();
  }
}
