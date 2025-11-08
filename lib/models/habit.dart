/// Model class representing a Habit
class Habit {
  final int? id;
  final String name;
  final String createdAt;
  final bool isDeleted;
  final String? deletedAt;

  Habit({
    this.id,
    required this.name,
    required this.createdAt,
    this.isDeleted = false,
    this.deletedAt,
  });

  /// Convert Habit to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt,
      'isDeleted': isDeleted ? 1 : 0,
      'deletedAt': deletedAt,
    };
  }

  /// Create Habit from database Map
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: map['createdAt'] as String,
      isDeleted: (map['isDeleted'] as int) == 1,
      deletedAt: map['deletedAt'] as String?,
    );
  }

  /// Create a copy of Habit with modified fields
  Habit copyWith({
    int? id,
    String? name,
    String? createdAt,
    bool? isDeleted,
    String? deletedAt,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  String toString() {
    return 'Habit{id: $id, name: $name, createdAt: $createdAt, isDeleted: $isDeleted, deletedAt: $deletedAt}';
  }
}
