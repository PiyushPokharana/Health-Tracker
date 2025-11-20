class HabitSession {
  final int? id;
  final int habitId;
  final int startTs; // epoch millis
  final int? endTs; // epoch millis, null while running
  final String? status; // complete|missed|skipped (optional for sessions)
  final String? note;
  final int createdAt; // epoch millis

  HabitSession({
    this.id,
    required this.habitId,
    required this.startTs,
    this.endTs,
    this.status,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'startTs': startTs,
      'endTs': endTs,
      'status': status,
      'note': note,
      'createdAt': createdAt,
    };
  }

  factory HabitSession.fromMap(Map<String, dynamic> map) {
    return HabitSession(
      id: map['id'] as int?,
      habitId: map['habitId'] as int,
      startTs: map['startTs'] as int,
      endTs: map['endTs'] as int?,
      status: map['status'] as String?,
      note: map['note'] as String?,
      createdAt: map['createdAt'] as int,
    );
  }

  HabitSession copyWith({
    int? id,
    int? habitId,
    int? startTs,
    int? endTs,
    String? status,
    String? note,
    int? createdAt,
  }) {
    return HabitSession(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      startTs: startTs ?? this.startTs,
      endTs: endTs ?? this.endTs,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
