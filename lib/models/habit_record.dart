/// Enum representing the status of a habit record
enum HabitStatus {
  complete,
  missed,
  skipped;

  /// Convert status to string for database storage
  String toDbString() {
    return name;
  }

  /// Create HabitStatus from database string
  static HabitStatus fromDbString(String status) {
    switch (status.toLowerCase()) {
      case 'complete':
        return HabitStatus.complete;
      case 'missed':
        return HabitStatus.missed;
      case 'skipped':
        return HabitStatus.skipped;
      default:
        throw ArgumentError('Invalid status: $status');
    }
  }
}

/// Model class representing a habit record for a specific date
class HabitRecord {
  final int? id;
  final int habitId;
  final String date; // Stored as ISO8601 format (yyyy-MM-dd)
  final HabitStatus status;
  final String? note;

  HabitRecord({
    this.id,
    required this.habitId,
    required this.date,
    required this.status,
    this.note,
  });

  /// Convert HabitRecord to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date,
      'status': status.toDbString(),
      'note': note,
    };
  }

  /// Create HabitRecord from database Map
  factory HabitRecord.fromMap(Map<String, dynamic> map) {
    return HabitRecord(
      id: map['id'] as int?,
      habitId: map['habitId'] as int,
      date: map['date'] as String,
      status: HabitStatus.fromDbString(map['status'] as String),
      note: map['note'] as String?,
    );
  }

  /// Create a copy of HabitRecord with modified fields
  HabitRecord copyWith({
    int? id,
    int? habitId,
    String? date,
    HabitStatus? status,
    String? note,
  }) {
    return HabitRecord(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      date: date ?? this.date,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }

  @override
  String toString() {
    return 'HabitRecord{id: $id, habitId: $habitId, date: $date, status: $status, note: $note}';
  }
}
