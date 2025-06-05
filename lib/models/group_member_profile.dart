import 'package:flutter/material.dart';

class GroupMemberProfile {
  final String userId;
  final String firstName;
  final String lastName;
  final DateTime? birthday;

  GroupMemberProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.birthday,
  });

  factory GroupMemberProfile.fromMap(Map<String, dynamic> map) {
    return GroupMemberProfile(
      userId: map['user_id'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      birthday: map['birthday'] != null ? DateTime.parse(map['birthday'] as String) : null,
    );
  }

  String get fullName => '$firstName $lastName';
}
