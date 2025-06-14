import 'package:flutter/material.dart';
import 'package:birthday_app/app_route_path.dart';
import 'package:birthday_app/screens/home_screen.dart';
import 'package:birthday_app/screens/confirm_invite_screen.dart';
import 'package:birthday_app/screens/confirm_friendship_screen.dart';
import 'package:birthday_app/screens/signup_screen.dart';
import 'package:birthday_app/screens/confirm_profile_screen.dart';
import 'package:birthday_app/screens/see_post_screen.dart'; // Import SeePostScreen
import 'package:birthday_app/screens/user_profile_page.dart'; // Import UserProfilePage
import 'package:birthday_app/screens/wish_screen.dart'; // Import WishScreen
import 'package:birthday_app/models/user_profile.dart'; // Import UserProfile
import 'package:birthday_app/services/friend_service.dart'; // Import FriendService
import 'package:supabase_flutter/supabase_flutter.dart';

class AppRouterDelegate extends RouterDelegate<AppRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<AppRoutePath> {
  final GlobalKey<NavigatorState> navigatorKey;
  final FriendService _friendService; // Add FriendService instance

  AppRoutePath? _currentPath;
  bool _loggedIn;
  bool _isProfileConfirmed;

  AppRouterDelegate()
      : navigatorKey = GlobalKey<NavigatorState>(),
        _loggedIn = Supabase.instance.client.auth.currentUser != null,
        _isProfileConfirmed = false,
        _friendService = FriendService(Supabase.instance.client) { // Initialize FriendService
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
              child: ConfirmInviteScreen(
                  inviteCode: _currentPath!.inviteCode!,
                  isGroupInvite: _currentPath!.isGroupInvite,
                  routerDelegate: this)),

        if (_currentPath?.friendId != null)
          MaterialPage(
              child: ConfirmFriendshipScreen(friendId: _currentPath!.friendId!)),

        if (_currentPath?.isPostsByGroup == true)
          MaterialPage(
              child: SeePostScreen(
                  selectedGroupId: _currentPath!.postsByGroupId,
                  selectedFriendId: null)),

        if (_currentPath?.isPostsByFriend == true)
          MaterialPage(
              child: Builder(
                builder: (context) {
                  debugPrint('AppRouterDelegate: Building SeePostScreen for friend. selectedFriendId: ${_currentPath!.postsByFriendId}');
                  return SeePostScreen(
                      selectedFriendId: _currentPath!.postsByFriendId,
                      selectedGroupId: null);
                },
              )),

        if (_currentPath?.isSendHbWish == true)
          MaterialPage(
            child: FutureBuilder<UserProfile?>(
              future: _friendService.fetchUserProfileById(_currentPath!.hbWishFriendId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Error')),
                    body: Center(child: Text('Error: ${snapshot.error}')),
                  );
                } else if (snapshot.hasData && snapshot.data != null) {
                  final userProfile = snapshot.data!;

                  return UserProfilePage(userProfile: userProfile);
                } else {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Friend Not Found')),
                    body: const Center(child: Text('Friend profile not found.')),
                  );
                }
              },
            ),
          ),

        if (_currentPath?.isWish == true)
          MaterialPage(
            child: WishScreen(wishId: _currentPath!.wishId!),
          ),
      ],
      onPopPage: (route, result) => route.didPop(result),
    );
  }

  @override
  Future<void> setNewRoutePath(AppRoutePath configuration) async {
    debugPrint('AppRouterDelegate: setNewRoutePath called with configuration: $configuration');
    if (configuration.isPostsByFriend) {
      debugPrint('AppRouterDelegate: postsByFriendId in configuration: ${configuration.postsByFriendId}');
    }
    if (configuration.isWish) {
      debugPrint('AppRouterDelegate: wishId in configuration: ${configuration.wishId}');
    }
    _currentPath = configuration;
    await _checkProfileConfirmation(); // Ensure profile status is up-to-date
    notifyListeners();
  }

  void goHome() {
    _currentPath = AppRoutePath.home();
    notifyListeners();
  }
}
