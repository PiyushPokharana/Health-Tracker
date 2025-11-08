import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'habit.dart';
import 'habit_record.dart';

/// Manager class for habit-related business logic
class HabitManager {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Map<int, List<HabitRecord>> _habitRecordsCache = {};

  // ==================== HABIT OPERATIONS ====================

  /// Load all non-deleted habits
  Future<List<Habit>> loadHabits() async {
    final habits = await _dbHelper.getAllHabits(includeDeleted: false);

    // Auto-cleanup: permanently delete habits that have been deleted for >30 days
    final now = DateTime.now();
    for (var habit in await _dbHelper.getAllHabits(includeDeleted: true)) {
      if (habit.isDeleted && habit.deletedAt != null) {
        final deletedDate = DateTime.parse(habit.deletedAt!);
        if (now.difference(deletedDate).inDays > 30) {
          await _dbHelper.deleteHabitPermanently(habit.id!);
        }
      }
    }

    return habits;
  }

  /// Load habits from trash (soft-deleted)
  Future<List<Habit>> loadDeletedHabits() async {
    final allHabits = await _dbHelper.getAllHabits(includeDeleted: true);
    return allHabits.where((h) => h.isDeleted).toList();
  }

  /// Add a new habit
  Future<int> addHabit(String name) async {
    final habit = Habit(
      name: name,
      createdAt: DateTime.now().toIso8601String(),
      isDeleted: false,
    );
    return await _dbHelper.insertHabit(habit);
  }

  /// Update an existing habit
  Future<void> updateHabit(Habit habit) async {
    await _dbHelper.updateHabit(habit);
    // Clear cache for this habit's records
    _habitRecordsCache.remove(habit.id);
  }

  /// Soft-delete a habit (move to trash)
  Future<void> deleteHabit(int habitId) async {
    final habit = await _dbHelper.getHabit(habitId);
    if (habit != null) {
      final deletedHabit = habit.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now().toIso8601String(),
      );
      await _dbHelper.updateHabit(deletedHabit);
      _habitRecordsCache.remove(habitId);
    }
  }

  /// Restore a habit from trash
  Future<void> restoreHabit(int habitId) async {
    final habit = await _dbHelper.getHabit(habitId);
    if (habit != null && habit.isDeleted) {
      final restoredHabit = habit.copyWith(
        isDeleted: false,
        deletedAt: null,
      );
      await _dbHelper.updateHabit(restoredHabit);
    }
  }

  /// Permanently delete a habit and all its records
  Future<void> permanentlyDeleteHabit(int habitId) async {
    await _dbHelper.deleteHabitPermanently(habitId);
    _habitRecordsCache.remove(habitId);
  }

  // ==================== HABIT RECORD OPERATIONS ====================

  /// Add or update a habit record for a specific date
  Future<void> addOrUpdateRecord(
    int habitId,
    DateTime date,
    HabitStatus status, {
    String? note,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // Check if record exists
    final existingRecord =
        await _dbHelper.getHabitRecordByDate(habitId, dateStr);

    if (existingRecord != null) {
      // Update existing record
      final updatedRecord = existingRecord.copyWith(
        status: status,
        note: note,
      );
      await _dbHelper.updateHabitRecord(updatedRecord);
    } else {
      // Insert new record
      final record = HabitRecord(
        habitId: habitId,
        date: dateStr,
        status: status,
        note: note,
      );
      await _dbHelper.insertHabitRecord(record);
    }

    // Clear cache for this habit
    _habitRecordsCache.remove(habitId);
  }

  /// Delete a habit record
  Future<void> deleteRecord(int recordId) async {
    final record = await _dbHelper.getHabitRecord(recordId);
    if (record != null) {
      await _dbHelper.deleteHabitRecord(recordId);
      _habitRecordsCache.remove(record.habitId);
    }
  }

  /// Get all records for a specific habit
  Future<List<HabitRecord>> getRecordsForHabit(int habitId) async {
    // Check cache first
    if (_habitRecordsCache.containsKey(habitId)) {
      return _habitRecordsCache[habitId]!;
    }

    // Load from database and cache
    final records = await _dbHelper.getHabitRecords(habitId);
    _habitRecordsCache[habitId] = records;
    return records;
  }

  /// Get record for a specific habit and date
  Future<HabitRecord?> getRecordForDate(int habitId, DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return await _dbHelper.getHabitRecordByDate(habitId, dateStr);
  }

  // ==================== STATISTICS & STREAKS ====================

  /// Calculate current streak for a habit
  /// Rules:
  /// - Complete: continues streak
  /// - Missed: breaks streak
  /// - Skipped: ignored (doesn't break or continue)
  Future<int> getCurrentStreak(int habitId) async {
    final records = await getRecordsForHabit(habitId);
    if (records.isEmpty) return 0;

    // Sort by date descending (most recent first)
    records.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    for (var record in records) {
      if (record.date.compareTo(today) > 0) {
        // Skip future dates
        continue;
      }

      if (record.status == HabitStatus.complete) {
        streak++;
      } else if (record.status == HabitStatus.missed) {
        // Missed breaks the streak
        break;
      }
      // Skipped is ignored, continue checking
    }

    return streak;
  }

  /// Calculate maximum streak ever achieved for a habit
  Future<int> getMaxStreak(int habitId) async {
    final records = await getRecordsForHabit(habitId);
    if (records.isEmpty) return 0;

    // Sort by date ascending
    records.sort((a, b) => a.date.compareTo(b.date));

    int maxStreak = 0;
    int currentStreak = 0;

    for (var record in records) {
      if (record.status == HabitStatus.complete) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
      } else if (record.status == HabitStatus.missed) {
        // Missed breaks the streak
        currentStreak = 0;
      }
      // Skipped is ignored
    }

    return maxStreak;
  }

  /// Get statistics for a habit
  Future<Map<String, dynamic>> getHabitStatistics(int habitId) async {
    final records = await getRecordsForHabit(habitId);

    if (records.isEmpty) {
      return {
        'totalRecords': 0,
        'completedCount': 0,
        'missedCount': 0,
        'skippedCount': 0,
        'completionRate': 0.0,
        'currentStreak': 0,
        'maxStreak': 0,
      };
    }

    int completedCount = 0;
    int missedCount = 0;
    int skippedCount = 0;

    for (var record in records) {
      switch (record.status) {
        case HabitStatus.complete:
          completedCount++;
          break;
        case HabitStatus.missed:
          missedCount++;
          break;
        case HabitStatus.skipped:
          skippedCount++;
          break;
      }
    }

    final totalRecords = records.length;
    final completionRate =
        totalRecords > 0 ? (completedCount / totalRecords) * 100 : 0.0;

    final currentStreak = await getCurrentStreak(habitId);
    final maxStreak = await getMaxStreak(habitId);

    return {
      'totalRecords': totalRecords,
      'completedCount': completedCount,
      'missedCount': missedCount,
      'skippedCount': skippedCount,
      'completionRate': completionRate,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
    };
  }

  /// Clear all cached data
  void clearCache() {
    _habitRecordsCache.clear();
  }
}
