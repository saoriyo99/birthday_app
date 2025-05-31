class UserProfile {
  final String id;
  final DateTime createdAt;
  final String firstName;
  final String lastName;
  final DateTime birthday;

  UserProfile({
    required this.id,
    required this.createdAt,
    required this.firstName,
    required this.lastName,
    required this.birthday,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      birthday: DateTime.parse(map['birthday'] as String),
    );
  }
}
