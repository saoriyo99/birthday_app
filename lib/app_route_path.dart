class AppRoutePath {
  final String? inviteCode;
  final String? friendId;
  final bool isConfirmProfile;
  final bool isHome;
  final bool isSignUp;

  AppRoutePath.home()
      : isHome = true,
        isSignUp = false,
        inviteCode = null,
        friendId = null,
        isConfirmProfile = false;

  AppRoutePath.signUp()
      : isSignUp = true,
        isHome = false,
        inviteCode = null,
        friendId = null,
        isConfirmProfile = false;

  AppRoutePath.confirmProfile()
      : isConfirmProfile = true,
        isHome = false,
        inviteCode = null,
        friendId = null,
        isSignUp = false;

  AppRoutePath.confirmInvite(this.inviteCode)
      : friendId = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false;

  AppRoutePath.confirmFriend(this.friendId)
      : inviteCode = null,
        isHome = false,
        isSignUp = false,
        isConfirmProfile = false;
}
