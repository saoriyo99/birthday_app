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

  AppRoutePath.home()
      : isHome = true,
        isSignUp = false,
        inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        postsByFriendId = null,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = false;

  AppRoutePath.signUp()
      : isSignUp = true,
        isHome = false,
        inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        postsByFriendId = null,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = false;

  AppRoutePath.confirmProfile()
      : isConfirmProfile = true,
        isHome = false,
        inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        postsByFriendId = null,
        isSignUp = false,
        isPostsByGroup = false,
        isPostsByFriend = false;

  AppRoutePath.confirmInvite(this.inviteCode)
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
        isPostsByFriend = false;

  AppRoutePath.postsByGroup(this.postsByGroupId)
      : inviteCode = null,
        friendId = null,
        postsByFriendId = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false,
        isPostsByGroup = true,
        isPostsByFriend = false;

  AppRoutePath.postsByFriend(this.postsByFriendId)
      : inviteCode = null,
        friendId = null,
        postsByGroupId = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false,
        isPostsByGroup = false,
        isPostsByFriend = true;
}
