class GroupMember {
  final String id;
  final String groupId;
  final String userId;
  final DateTime joinedAt;
  final String name; // Added name field
  final String role; // Added role field

  GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.joinedAt,
    required this.name, // Added to constructor
    required this.role, // Added to constructor
  });

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      id: map['id'] as String,
      groupId: map['group_id'] as String,
      userId: map['user_id'] as String,
      joinedAt: DateTime.parse(map['joined_at'] as String),
      name: map['name'] as String,
      role: map['role'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'joinedAt': joinedAt.toIso8601String(),
      'name': name,
      'role': role,
    };
  }
}
