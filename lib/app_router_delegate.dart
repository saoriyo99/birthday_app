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

  AppRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  @override
  AppRoutePath? get currentConfiguration => _currentPath;

  @override
  Widget build(BuildContext context) {
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

        if (_currentPath?.isSignUp ?? false)
          MaterialPage(child: SignUpScreen()),

        if (_currentPath?.isConfirmProfile ?? false)
          MaterialPage(child: ConfirmProfileScreen(
            initialName: Supabase.instance.client.auth.currentUser?.userMetadata?['full_name'] ?? '',
            initialEmail: Supabase.instance.client.auth.currentUser?.email ?? '',
            userId: Supabase.instance.client.auth.currentUser?.id ?? '',
          )),
      ],
      onPopPage: (route, result) => route.didPop(result),
    );
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    _currentPath = configuration;
  }
}
