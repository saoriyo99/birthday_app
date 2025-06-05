import 'package:flutter/foundation.dart';

/// The base URL for deep links and invites, switches between local and prod.
const String kProdBaseUrl = 'https://saoriyo99.github.io/birthday_app/';
const String kLocalBaseUrl = 'http://localhost:3912/';

String get baseAppUrl => kDebugMode ? kLocalBaseUrl : kProdBaseUrl;

/// Helper to generate invite links for friend or group.
String inviteLink(String code) => "${baseAppUrl}#/invite?code=$code";
String groupInviteLink(String code) => "${baseAppUrl}#/joingroup?code=$code";
