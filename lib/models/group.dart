import 'package:birthday_app/models/group_member_profile.dart';

class Group {
  final String id;
  final DateTime createdAt;
  final String name;
  final String type;
  final DateTime? endDate;
  final List<GroupMemberProfile> members;

  Group({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.type,
    this.endDate,
    required this.members,
  });

  factory Group.fromMap(Map<String, dynamic> map) {
    List<GroupMemberProfile> members = (map['members'] as List?)
        ?.map((i) => GroupMemberProfile.fromMap(i as Map<String, dynamic>))
        .toList() ?? [];

    return Group(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      name: map['name'] as String,
      type: map['type'] as String,
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
      members: members,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'name': name,
      'type': type,
      'endDate': endDate?.toIso8601String(),
      'members': members.map((member) => member.toMap()).toList(),
    };
  }
}
