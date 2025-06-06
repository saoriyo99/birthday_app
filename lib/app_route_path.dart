import 'package:flutter/foundation.dart';

class AppRoutePath {
  final String? inviteCode;
  final String? friendId;
  final String? postsByGroupId;
  final String? postsByFriendId;
  final String? hbWishFriendId; // New: To store friend ID for birthday wish
  final bool isConfirmProfile;
  final bool isHome;
  final bool isSignUp;
  final bool isPostsByGroup;
  final bool isPostsByFriend;
  final bool isGroupInvite; // New: To distinguish group invites
  final bool isSendHbWish; // New: To identify send HB wish route
  final String? wishId; // New: To store wish ID for WishScreen
  final bool isWish; // New: To identify wish screen route

  AppRoutePath.home()
      : isHome = true,
        isSignUp = false,
        inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        postsByFriendId = null,
        hbWishFriendId = null,
        wishId = null,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = false,
        isGroupInvite = false,
        isSendHbWish = false,
        isWish = false;

  AppRoutePath.signUp()
      : isSignUp = true,
        isHome = false,
        inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        postsByFriendId = null,
        hbWishFriendId = null,
        wishId = null,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = false,
        isGroupInvite = false,
        isSendHbWish = false,
        isWish = false;

  AppRoutePath.confirmProfile()
      : isConfirmProfile = true,
        isHome = false,
        inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        postsByFriendId = null,
        hbWishFriendId = null,
        wishId = null,
        isSignUp = false,
        isPostsByGroup = false,
        isPostsByFriend = false,
        isGroupInvite = false,
        isSendHbWish = false,
        isWish = false;

  AppRoutePath.confirmInvite(this.inviteCode, {this.isGroupInvite = false})
      : friendId = null,
        postsByGroupId = null,
        postsByFriendId = null,
        hbWishFriendId = null,
        wishId = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = false,
        isSendHbWish = false,
        isWish = false;

  AppRoutePath.confirmFriend(this.friendId)
      : inviteCode = null,
        postsByGroupId = null,
        postsByFriendId = null,
        hbWishFriendId = null,
        wishId = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = false,
        isGroupInvite = false,
        isSendHbWish = false,
        isWish = false;

  AppRoutePath.postsByGroup(this.postsByGroupId)
      : inviteCode = null,
        friendId = null,
        postsByFriendId = null,
        hbWishFriendId = null,
        wishId = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false,
        isPostsByGroup = true,
        isPostsByFriend = false,
        isGroupInvite = false,
        isSendHbWish = false,
        isWish = false;

  AppRoutePath.postsByFriend(this.postsByFriendId)
      : inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        hbWishFriendId = null,
        wishId = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = true,
        isGroupInvite = false,
        isSendHbWish = false,
        isWish = false {
    debugPrint('AppRoutePath.postsByFriend constructor: postsByFriendId = $postsByFriendId');
  }

  AppRoutePath.sendHbWish(this.hbWishFriendId)
      : inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        postsByFriendId = null,
        wishId = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = false,
        isGroupInvite = false,
        isSendHbWish = true,
        isWish = false;

  AppRoutePath.wish(this.wishId)
      : inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        postsByFriendId = null,
        hbWishFriendId = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = false,
        isGroupInvite = false,
        isSendHbWish = false,
        isWish = true;
}
