import 'package:intl/intl.dart';
import 'database_helper.dart';
import 'habit.dart';
import 'habit_record.dart';
import 'habit_session.dart';

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
      timerEnabled: false,
      allowMultipleSessions: false,
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
  Future<HabitRecord?> deleteRecord(int recordId) async {
    final record = await _dbHelper.getHabitRecord(recordId);
    if (record != null) {
      await _dbHelper.deleteHabitRecord(recordId);
      _habitRecordsCache.remove(record.habitId);
    }
    return record;
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
  /// - Days must be consecutive (gaps break the streak unless marked as skipped)
  Future<int> getCurrentStreak(int habitId) async {
    final records = await getRecordsForHabit(habitId);
    if (records.isEmpty) return 0;

    // Sort by date descending (most recent first)
    records.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    DateTime? expectedDate;

    for (var record in records) {
      final recordDate = DateTime.parse(record.date);

      // Skip future dates
      if (record.date.compareTo(todayStr) > 0) {
        continue;
      }

      // Initialize expected date on first iteration
      if (expectedDate == null) {
        expectedDate = today;
      }

      // Check if this record is on the expected date or earlier
      // If there's a gap, check if it's filled with "skipped" or if it breaks the streak
      while (expectedDate!.isAfter(recordDate) &&
          DateFormat('yyyy-MM-dd').format(expectedDate) != record.date) {
        final expectedDateStr = DateFormat('yyyy-MM-dd').format(expectedDate);

        // Look for a record on the expected date
        final expectedRecord = records.firstWhere(
          (r) => r.date == expectedDateStr,
          orElse: () => HabitRecord(
            habitId: habitId,
            date: expectedDateStr,
            status: HabitStatus.missed, // Treat missing days as missed
          ),
        );

        // If the expected date was missed (or has no record), break the streak
        if (expectedRecord.status == HabitStatus.missed) {
          return streak;
        }
        // If skipped, move to previous day without breaking streak

        expectedDate = expectedDate.subtract(const Duration(days: 1));
      }

      // Now check the current record
      if (record.status == HabitStatus.complete) {
        streak++;
        // Move to the previous day
        expectedDate = recordDate.subtract(const Duration(days: 1));
      } else if (record.status == HabitStatus.missed) {
        // Missed explicitly breaks the streak
        break;
      } else if (record.status == HabitStatus.skipped) {
        // Skipped: move to previous day without incrementing streak
        expectedDate = recordDate.subtract(const Duration(days: 1));
      }
    }

    return streak;
  }

  /// Calculate maximum streak ever achieved for a habit
  /// Counts consecutive complete days, where skipped days don't break the streak
  Future<int> getMaxStreak(int habitId) async {
    final records = await getRecordsForHabit(habitId);
    if (records.isEmpty) return 0;

    // Sort by date ascending
    records.sort((a, b) => a.date.compareTo(b.date));

    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    for (var record in records) {
      final recordDate = DateTime.parse(record.date);

      if (lastDate != null) {
        final daysDiff = recordDate.difference(lastDate).inDays;

        // If there's a gap of more than 1 day, check if we need to break the streak
        if (daysDiff > 1) {
          // Check if all days in the gap are marked as skipped
          bool hasGap = false;
          for (int i = 1; i < daysDiff; i++) {
            final gapDate = lastDate.add(Duration(days: i));
            final gapDateStr = DateFormat('yyyy-MM-dd').format(gapDate);
            final gapRecord = records.firstWhere(
              (r) => r.date == gapDateStr,
              orElse: () => HabitRecord(
                habitId: habitId,
                date: gapDateStr,
                status: HabitStatus.missed,
              ),
            );

            // If any day in the gap is not skipped, break the streak
            if (gapRecord.status != HabitStatus.skipped) {
              hasGap = true;
              break;
            }
          }

          if (hasGap) {
            // Reset streak due to gap
            currentStreak = 0;
          }
        }
      }

      if (record.status == HabitStatus.complete) {
        currentStreak++;
        if (currentStreak > maxStreak) {
          maxStreak = currentStreak;
        }
        lastDate = recordDate;
      } else if (record.status == HabitStatus.missed) {
        // Missed explicitly breaks the streak
        currentStreak = 0;
        lastDate = recordDate;
      } else if (record.status == HabitStatus.skipped) {
        // Skipped: don't break streak, but don't increment either
        lastDate = recordDate;
      }
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

  // ==================== SESSION/TIMER WRAPPERS ====================

  Future<int> createSession({
    required int habitId,
    required int startTs,
    String? status,
    String? note,
  }) async {
    return _dbHelper.createSession(
      habitId: habitId,
      startTs: startTs,
      status: status,
      note: note,
    );
  }

  Future<int> endSession({required int sessionId, required int endTs}) async {
    return _dbHelper.endSession(sessionId: sessionId, endTs: endTs);
  }

  Future<HabitSession?> getRunningSession(int habitId) async {
    return _dbHelper.getRunningSession(habitId);
  }

  Future<List<HabitSession>> getAllRunningSessions() async {
    return _dbHelper.getAllRunningSessions();
  }

  Future<List<HabitSession>> getSessionsForDay(
      int habitId, DateTime day) async {
    return _dbHelper.getSessionsForDay(habitId, day);
  }

  Future<int> deleteSession(int sessionId) async {
    return _dbHelper.deleteSession(sessionId);
  }

  Future<int> deleteAllSessionsForHabit(int habitId) async {
    return _dbHelper.deleteAllSessionsForHabit(habitId);
  }

  // ==================== BULK QUERIES ====================

  Future<List<HabitRecord>> getRecordsInRange(
      DateTime startInclusive, DateTime endInclusive) async {
    final fmt = DateFormat('yyyy-MM-dd');
    final startStr = fmt.format(startInclusive);
    final endStr = fmt.format(endInclusive);
    return _dbHelper.getHabitRecordsInRange(startStr, endStr);
  }
}
