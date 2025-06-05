class Friend {
  final String id;
  final String firstName;
  final String lastName;

  Friend({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      id: map['friend_id'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'friend_id': id,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}
