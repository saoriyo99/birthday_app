class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthday;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthday,
    required this.createdAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      birthday: DateTime.parse(map['birthday'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'birthday': birthday.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
