class Group {
  final String id;
  final DateTime createdAt;
  final String name;
  final String type;
  final DateTime? endDate;

  Group({
    required this.id,
    required this.createdAt,
    required this.name,
    required this.type,
    this.endDate,
  });

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      name: map['name'] as String,
      type: map['type'] as String,
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date'] as String) : null,
    );
  }
}
