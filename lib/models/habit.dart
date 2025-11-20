/// Model class representing a Habit
class Habit {
  final int? id;
  final String name;
  final String createdAt;
  final bool isDeleted;
  final String? deletedAt;
  final bool timerEnabled;
  final bool allowMultipleSessions;

  Habit({
    this.id,
    required this.name,
    required this.createdAt,
    this.isDeleted = false,
    this.deletedAt,
    this.timerEnabled = false,
    this.allowMultipleSessions = false,
  });

  /// Convert Habit to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt,
      'isDeleted': isDeleted ? 1 : 0,
      'deletedAt': deletedAt,
      'timerEnabled': timerEnabled ? 1 : 0,
      'allowMultipleSessions': allowMultipleSessions ? 1 : 0,
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
      timerEnabled: ((map['timerEnabled'] as int?) ?? 0) == 1,
      allowMultipleSessions: ((map['allowMultipleSessions'] as int?) ?? 0) == 1,
    );
  }

  /// Create a copy of Habit with modified fields
  Habit copyWith({
    int? id,
    String? name,
    String? createdAt,
    bool? isDeleted,
    String? deletedAt,
    bool? timerEnabled,
    bool? allowMultipleSessions,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      timerEnabled: timerEnabled ?? this.timerEnabled,
      allowMultipleSessions:
          allowMultipleSessions ?? this.allowMultipleSessions,
    );
  }

  @override
  String toString() {
    return 'Habit{id: $id, name: $name, createdAt: $createdAt, isDeleted: $isDeleted, deletedAt: $deletedAt}';
  }
}
