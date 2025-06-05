class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthday;
  final DateTime createdAt;
  final String? groups; // Add this line

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthday,
    required this.createdAt,
    this.groups, // Add this line
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      firstName: map['first_name'] as String,
      lastName: map['last_name'] as String,
      birthday: DateTime.parse(map['birthday'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      groups: map['groups'] as String?, // Add this line
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'birthday': birthday.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'groups': groups, // Add this line
    };
  }

  /// Creates a new [UserProfile] instance with updated values.
  ///
  /// This method is useful for creating a new instance of [UserProfile]
  /// with some properties changed, while keeping others the same.
  UserProfile copyWith({
    String? id,
    String? firstName,
    String? lastName,
    DateTime? birthday,
    DateTime? createdAt,
    String? groups,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      birthday: birthday ?? this.birthday,
      createdAt: createdAt ?? this.createdAt,
      groups: groups ?? this.groups,
    );
  }
}
