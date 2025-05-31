class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final DateTime joinedAt;

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.joinedAt,
  });

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      userId: map['user_id'] as String,
      joinedAt: DateTime.parse(map['joined_at'] as String),
    );
  }
}
