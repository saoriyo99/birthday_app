

class Friendship {
  final String user1Id;
  final String user2Id;
  final String status; // e.g., 'accepted', 'pending', 'blocked'

  Friendship({
    required this.user1Id,
    required this.user2Id,
    required this.status,
  });

  factory Friendship.fromMap(Map<String, dynamic> map) {
    return Friendship(
      user1Id: map['user_1_id'] as String,
      user2Id: map['user_2_id'] as String,
      status: map['status'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_1_id': user1Id,
      'user_2_id': user2Id,
      'status': status,
    };
  }
}
