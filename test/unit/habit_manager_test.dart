import 'package:flutter_test/flutter_test.dart';
import 'package:daily_success_tracker_1/models/habit_record.dart';
import 'package:daily_success_tracker_1/models/habit_manager.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Mock PathProvider for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String testId;

  MockPathProviderPlatform(this.testId);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/tmp/test_db_manager_$testId';
  }
}

/// Unit tests for HabitManager
/// Tests CRUD operations, streak calculations, and statistics
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite ffi for desktop testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Use unique database for each test run
  final testId = DateTime.now().millisecondsSinceEpoch.toString();
  PathProviderPlatform.instance = MockPathProviderPlatform(testId);

  late HabitManager habitManager;

  setUp(() {
    habitManager = HabitManager();
  });

  tearDown(() {
    habitManager.clearCache();
  });

  group('Habit CRUD Operations', () {
    test('Create habit - should add new habit to database', () async {
      final id = await habitManager.addHabit('Test Habit');

      expect(id, greaterThan(0));

      final habits = await habitManager.loadHabits();
      expect(habits.length, greaterThanOrEqualTo(1));
      expect(habits.any((h) => h.name == 'Test Habit'), isTrue);
    });

    test('Read habits - should load all non-deleted habits', () async {
      // Add multiple habits
      await habitManager.addHabit('Habit 1');
      await habitManager.addHabit('Habit 2');
      await habitManager.addHabit('Habit 3');

      final habits = await habitManager.loadHabits();

      expect(habits.where((h) => h.name.startsWith('Habit ')).length,
          greaterThanOrEqualTo(3));
    });

    test('Soft delete habit - should mark habit as deleted', () async {
      final id = await habitManager.addHabit('To Delete');

      await habitManager.deleteHabit(id);
      final habits = await habitManager.loadHabits();

      expect(habits.where((h) => h.name == 'To Delete').isEmpty, isTrue);

      final deletedHabits = await habitManager.loadDeletedHabits();
      expect(deletedHabits.any((h) => h.name == 'To Delete' && h.isDeleted),
          isTrue);
    });

    test('Restore habit - should restore deleted habit', () async {
      final id = await habitManager.addHabit('To Restore');

      await habitManager.deleteHabit(id);
      await habitManager.restoreHabit(id);
      final habits = await habitManager.loadHabits();

      expect(habits.any((h) => h.name == 'To Restore' && !h.isDeleted), isTrue);
    });

    test('Permanent delete habit - should remove habit completely', () async {
      final id = await habitManager.addHabit('To Permanently Delete');

      await habitManager.deleteHabit(id);
      await habitManager.permanentlyDeleteHabit(id);

      final deletedHabits = await habitManager.loadDeletedHabits();
      expect(
          deletedHabits.where((h) => h.name == 'To Permanently Delete').isEmpty,
          isTrue);
    });
  });

  group('Habit Record Operations', () {
    late int habitId;

    setUp(() async {
      habitId = await habitManager.addHabit('Test Habit for Records');
    });

    test('Add record - should create new habit record', () async {
      final today = DateTime.now();

      await habitManager.addOrUpdateRecord(
        habitId,
        today,
        HabitStatus.complete,
        note: 'Test note',
      );

      final record = await habitManager.getRecordForDate(habitId, today);
      expect(record, isNotNull);
      expect(record!.status, equals(HabitStatus.complete));
      expect(record.note, equals('Test note'));
    });

    test('Update record - should modify existing record', () async {
      final today = DateTime.now();

      await habitManager.addOrUpdateRecord(
        habitId,
        today,
        HabitStatus.complete,
      );

      await habitManager.addOrUpdateRecord(
        habitId,
        today,
        HabitStatus.missed,
        note: 'Updated note',
      );

      final record = await habitManager.getRecordForDate(habitId, today);
      expect(record!.status, equals(HabitStatus.missed));
      expect(record.note, equals('Updated note'));
    });

    test('Get records for habit - should return all records', () async {
      // Add multiple records
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now().subtract(const Duration(days: 2)),
        HabitStatus.complete,
      );
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now().subtract(const Duration(days: 1)),
        HabitStatus.complete,
      );
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now(),
        HabitStatus.missed,
      );

      final records = await habitManager.getRecordsForHabit(habitId);
      expect(records.length, greaterThanOrEqualTo(3));
    });
  });

  group('Streak Calculations', () {
    late int habitId;

    setUp(() async {
      habitId = await habitManager.addHabit('Streak Test Habit');

      // Clear any existing records
      final existingRecords = await habitManager.getRecordsForHabit(habitId);
      for (var record in existingRecords) {
        if (record.id != null) {
          await habitManager.deleteRecord(record.id!);
        }
      }
    });

    test('Current streak - consecutive complete days', () async {
      // Add 5 consecutive complete days ending today
      for (int i = 4; i >= 0; i--) {
        await habitManager.addOrUpdateRecord(
          habitId,
          DateTime.now().subtract(Duration(days: i)),
          HabitStatus.complete,
        );
      }

      final streak = await habitManager.getCurrentStreak(habitId);
      expect(streak, equals(5));
    });

    test('Current streak - broken by missed day', () async {
      // Add complete days with a missed day in between
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now().subtract(const Duration(days: 3)),
        HabitStatus.complete,
      );
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now().subtract(const Duration(days: 2)),
        HabitStatus.missed, // Breaks streak
      );
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now().subtract(const Duration(days: 1)),
        HabitStatus.complete,
      );
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now(),
        HabitStatus.complete,
      );

      final streak = await habitManager.getCurrentStreak(habitId);
      expect(streak, equals(2)); // Only last 2 days count
    });

    test('Current streak - skipped days ignored', () async {
      // Add complete days with skipped days (should not break streak)
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now().subtract(const Duration(days: 3)),
        HabitStatus.complete,
      );
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now().subtract(const Duration(days: 2)),
        HabitStatus.skipped, // Should not break streak
      );
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now().subtract(const Duration(days: 1)),
        HabitStatus.complete,
      );
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now(),
        HabitStatus.complete,
      );

      final streak = await habitManager.getCurrentStreak(habitId);
      expect(streak, equals(3)); // 3 complete days, skipped day ignored
    });

    test('Current streak - no records returns 0', () async {
      final streak = await habitManager.getCurrentStreak(habitId);
      expect(streak, equals(0));
    });

    test('Max streak - finds longest streak', () async {
      // Create two streaks: 3 days, break, 5 days
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now().subtract(const Duration(days: 10)),
        HabitStatus.complete,
      );
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now().subtract(const Duration(days: 9)),
        HabitStatus.complete,
      );
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now().subtract(const Duration(days: 8)),
        HabitStatus.complete,
      );
      // Break
      await habitManager.addOrUpdateRecord(
        habitId,
        DateTime.now().subtract(const Duration(days: 7)),
        HabitStatus.missed,
      );
      // New streak of 5
      for (int i = 4; i >= 0; i--) {
        await habitManager.addOrUpdateRecord(
          habitId,
          DateTime.now().subtract(Duration(days: i)),
          HabitStatus.complete,
        );
      }

      final maxStreak = await habitManager.getMaxStreak(habitId);
      expect(maxStreak, equals(5)); // Longest streak
    });
  });

  group('Statistics', () {
    late int habitId;

    setUp(() async {
      habitId = await habitManager.addHabit('Stats Test Habit');

      // Clear any existing records
      final existingRecords = await habitManager.getRecordsForHabit(habitId);
      for (var record in existingRecords) {
        if (record.id != null) {
          await habitManager.deleteRecord(record.id!);
        }
      }

      // Add test data: 5 complete, 2 missed, 3 skipped
      await habitManager.addOrUpdateRecord(
          habitId,
          DateTime.now().subtract(const Duration(days: 9)),
          HabitStatus.complete);
      await habitManager.addOrUpdateRecord(
          habitId,
          DateTime.now().subtract(const Duration(days: 8)),
          HabitStatus.complete);
      await habitManager.addOrUpdateRecord(habitId,
          DateTime.now().subtract(const Duration(days: 7)), HabitStatus.missed);
      await habitManager.addOrUpdateRecord(
          habitId,
          DateTime.now().subtract(const Duration(days: 6)),
          HabitStatus.complete);
      await habitManager.addOrUpdateRecord(
          habitId,
          DateTime.now().subtract(const Duration(days: 5)),
          HabitStatus.skipped);
      await habitManager.addOrUpdateRecord(
          habitId,
          DateTime.now().subtract(const Duration(days: 4)),
          HabitStatus.complete);
      await habitManager.addOrUpdateRecord(
          habitId,
          DateTime.now().subtract(const Duration(days: 3)),
          HabitStatus.skipped);
      await habitManager.addOrUpdateRecord(habitId,
          DateTime.now().subtract(const Duration(days: 2)), HabitStatus.missed);
      await habitManager.addOrUpdateRecord(
          habitId,
          DateTime.now().subtract(const Duration(days: 1)),
          HabitStatus.complete);
      await habitManager.addOrUpdateRecord(
          habitId, DateTime.now(), HabitStatus.skipped);
    });

    test('Get habit statistics - should calculate all metrics', () async {
      final stats = await habitManager.getHabitStatistics(habitId);

      expect(stats['totalRecords'], equals(10));
      expect(stats['completedCount'], equals(5));
      expect(stats['missedCount'], equals(2));
      expect(stats['skippedCount'], equals(3));
      expect(stats['completionRate'], equals(50.0)); // 5 out of 10 = 50%
      expect(stats['currentStreak'], greaterThanOrEqualTo(0));
      expect(stats['maxStreak'], greaterThanOrEqualTo(0));
    });
  });

  group('Edge Cases', () {
    test('Delete non-existent habit - should handle gracefully', () async {
      // Should not throw, just do nothing
      await habitManager.deleteHabit(99999);
      expect(true, isTrue); // Passes if no exception thrown
    });

    test('Get records for non-existent habit', () async {
      final records = await habitManager.getRecordsForHabit(99999);
      expect(records, isEmpty);
    });

    test('Get statistics for habit with no records', () async {
      final habitId = await habitManager.addHabit('Empty Habit');

      final stats = await habitManager.getHabitStatistics(habitId);

      expect(stats['totalRecords'], equals(0));
      expect(stats['completedCount'], equals(0));
      expect(stats['completionRate'], equals(0.0));
      expect(stats['currentStreak'], equals(0));
      expect(stats['maxStreak'], equals(0));
    });
  });
}
