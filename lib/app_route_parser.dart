import 'package:flutter/material.dart';
import 'package:birthday_app/app_route_path.dart';

class AppRouteParser extends RouteInformationParser<AppRoutePath> {
  @override
  Future<AppRoutePath> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location ?? '');

    if (uri.pathSegments.isEmpty) {
      return AppRoutePath.home();
    }

    final path = uri.pathSegments.first;

    if (path == 'invite' && uri.queryParameters.containsKey('code')) {
      return AppRoutePath.confirmInvite(uri.queryParameters['code']!, isGroupInvite: false);
    }

    if (path == 'joingroup' && uri.queryParameters.containsKey('code')) {
      return AppRoutePath.confirmInvite(uri.queryParameters['code']!, isGroupInvite: true);
    }

    if (path == 'addfriend' && uri.queryParameters.containsKey('userId')) {
      return AppRoutePath.confirmFriend(uri.queryParameters['userId']!);
    }

    // You can extend this easily
    return AppRoutePath.home();
  }

  @override
  RouteInformation? restoreRouteInformation(AppRoutePath configuration) {
    if (configuration.isHome) {
      return const RouteInformation(location: '/');
    }
    if (configuration.isSignUp) {
      return const RouteInformation(location: '/signup');
    }
    if (configuration.isConfirmProfile) {
      return const RouteInformation(location: '/confirm-profile');
    }
    if (configuration.inviteCode != null) {
      return RouteInformation(location: '/invite?code=${configuration.inviteCode}');
    }
    if (configuration.friendId != null) {
      return RouteInformation(location: '/addfriend?userId=${configuration.friendId}');
    }
    return const RouteInformation(location: '/');
  }
}
