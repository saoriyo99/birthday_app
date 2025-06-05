import 'package:flutter/foundation.dart';

class AppRoutePath {
  final String? inviteCode;
  final String? friendId;
  final String? postsByGroupId;
  final String? postsByFriendId;
  final bool isConfirmProfile;
  final bool isHome;
  final bool isSignUp;
  final bool isPostsByGroup;
  final bool isPostsByFriend;
  final bool isGroupInvite; // New: To distinguish group invites

  AppRoutePath.home()
      : isHome = true,
        isSignUp = false,
        inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        postsByFriendId = null,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = false,
        isGroupInvite = false;

  AppRoutePath.signUp()
      : isSignUp = true,
        isHome = false,
        inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        postsByFriendId = null,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = false,
        isGroupInvite = false;

  AppRoutePath.confirmProfile()
      : isConfirmProfile = true,
        isHome = false,
        inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        postsByFriendId = null,
        isSignUp = false,
        isPostsByGroup = false,
        isPostsByFriend = false,
        isGroupInvite = false; // Default to false for home

  AppRoutePath.confirmInvite(this.inviteCode, {this.isGroupInvite = false})
      : friendId = null,
        postsByGroupId = null,
        postsByFriendId = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = false;

  AppRoutePath.confirmFriend(this.friendId)
      : inviteCode = null,
        postsByGroupId = null,
        postsByFriendId = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = false,
        isGroupInvite = false;

  AppRoutePath.postsByGroup(this.postsByGroupId)
      : inviteCode = null,
        friendId = null,
        postsByFriendId = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false,
        isPostsByGroup = true,
        isPostsByFriend = false,
        isGroupInvite = false;

  AppRoutePath.postsByFriend(this.postsByFriendId)
      : inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = true,
        isGroupInvite = false { // Default to false for postsByFriend
    debugPrint('AppRoutePath.postsByFriend constructor: postsByFriendId = $postsByFriendId');
  }
}
