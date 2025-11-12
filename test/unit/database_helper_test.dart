import 'package:flutter_test/flutter_test.dart';
import 'package:hta/models/habit.dart';
import 'package:hta/models/habit_record.dart';
import 'package:hta/models/database_helper.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:intl/intl.dart';

/// Mock PathProvider for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String testId;

  MockPathProviderPlatform(this.testId);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/tmp/test_db_helper_$testId';
  }
}

/// Unit tests for DatabaseHelper
/// Tests database schema, migrations, and CRUD operations
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite ffi for desktop testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Use unique database for each test run
  final testId = DateTime.now().millisecondsSinceEpoch.toString();
  PathProviderPlatform.instance = MockPathProviderPlatform(testId);

  late DatabaseHelper dbHelper;

  setUp(() async {
    dbHelper = DatabaseHelper.instance;
  });
  group('Database Schema - Table Creation', () {
    test('Create database - should create Habits table with correct schema',
        () async {
      final db = await dbHelper.database;

      // Query table schema
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='Habits'");

      expect(tables.length, equals(1));
      expect(tables.first['name'], equals('Habits'));
    });

    test(
        'Create database - should create HabitRecords table with correct schema',
        () async {
      final db = await dbHelper.database;

      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='HabitRecords'");

      expect(tables.length, equals(1));
      expect(tables.first['name'], equals('HabitRecords'));
    });

    test('Create database - should create indexes on HabitRecords', () async {
      final db = await dbHelper.database;

      final indexes = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='HabitRecords'");

      final indexNames = indexes.map((idx) => idx['name'] as String).toList();
      expect(indexNames, contains('idx_habitId'));
      expect(indexNames, contains('idx_date'));
    });

    test('Habits table - should have correct columns', () async {
      final db = await dbHelper.database;

      final columns = await db.rawQuery("PRAGMA table_info(Habits)");
      final columnNames = columns.map((col) => col['name'] as String).toList();

      expect(columnNames,
          containsAll(['id', 'name', 'createdAt', 'isDeleted', 'deletedAt']));
    });

    test('HabitRecords table - should have correct columns', () async {
      final db = await dbHelper.database;

      final columns = await db.rawQuery("PRAGMA table_info(HabitRecords)");
      final columnNames = columns.map((col) => col['name'] as String).toList();

      expect(columnNames,
          containsAll(['id', 'habitId', 'date', 'status', 'note']));
    });

    test(
        'HabitRecords table - should have UNIQUE constraint on (habitId, date)',
        () async {
      // Insert a habit first
      final habitId = await dbHelper.insertHabit(Habit(
        name: 'Test Habit',
        createdAt: DateTime.now().toIso8601String(),
      ));

      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Insert first record
      await dbHelper.insertHabitRecord(HabitRecord(
        habitId: habitId,
        date: date,
        status: HabitStatus.complete,
      ));

      // Try to insert duplicate - should fail
      expect(
        () => dbHelper.insertHabitRecord(HabitRecord(
          habitId: habitId,
          date: date,
          status: HabitStatus.missed,
        )),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Habit CRUD Operations', () {
    test('Insert habit - should return valid ID and persist data', () async {
      final habit = Habit(
        name: 'Morning Exercise',
        createdAt: DateTime.now().toIso8601String(),
      );

      final id = await dbHelper.insertHabit(habit);

      expect(id, greaterThan(0));

      final retrieved = await dbHelper.getHabit(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Morning Exercise'));
      expect(retrieved.isDeleted, isFalse);
    });

    test('Get habit - should return null for non-existent ID', () async {
      final habit = await dbHelper.getHabit(99999);
      expect(habit, isNull);
    });

    test('Get all habits - should return only non-deleted habits by default',
        () async {
      // Insert active habit
      await dbHelper.insertHabit(Habit(
        name: 'Active Habit',
        createdAt: DateTime.now().toIso8601String(),
      ));

      // Insert deleted habit
      await dbHelper.insertHabit(Habit(
        name: 'Deleted Habit',
        createdAt: DateTime.now().toIso8601String(),
        isDeleted: true,
        deletedAt: DateTime.now().toIso8601String(),
      ));

      final activeHabits = await dbHelper.getAllHabits(includeDeleted: false);
      final allHabits = await dbHelper.getAllHabits(includeDeleted: true);

      expect(activeHabits.any((h) => h.name == 'Deleted Habit'), isFalse);
      expect(allHabits.any((h) => h.name == 'Deleted Habit'), isTrue);
    });

    test('Update habit - should modify existing habit', () async {
      final habit = Habit(
        name: 'Original Name',
        createdAt: DateTime.now().toIso8601String(),
      );

      final id = await dbHelper.insertHabit(habit);
      final updatedHabit = habit.copyWith(
        id: id,
        name: 'Updated Name',
      );

      await dbHelper.updateHabit(updatedHabit);
      final retrieved = await dbHelper.getHabit(id);

      expect(retrieved!.name, equals('Updated Name'));
    });

    test('Delete habit permanently - should remove habit and all records',
        () async {
      // Insert habit
      final habitId = await dbHelper.insertHabit(Habit(
        name: 'To Delete',
        createdAt: DateTime.now().toIso8601String(),
      ));

      // Insert some records
      await dbHelper.insertHabitRecord(HabitRecord(
        habitId: habitId,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        status: HabitStatus.complete,
      ));

      await dbHelper.insertHabitRecord(HabitRecord(
        habitId: habitId,
        date: DateFormat('yyyy-MM-dd')
            .format(DateTime.now().subtract(const Duration(days: 1))),
        status: HabitStatus.complete,
      ));

      // Delete habit
      await dbHelper.deleteHabitPermanently(habitId);

      // Verify habit is gone
      final habit = await dbHelper.getHabit(habitId);
      expect(habit, isNull);

      // Verify records are gone (cascade delete)
      final records = await dbHelper.getHabitRecords(habitId);
      expect(records, isEmpty);
    });
  });

  group('HabitRecord CRUD Operations', () {
    late int habitId;

    setUp(() async {
      habitId = await dbHelper.insertHabit(Habit(
        name: 'Test Habit for Records',
        createdAt: DateTime.now().toIso8601String(),
      ));
    });

    test('Insert habit record - should return valid ID and persist data',
        () async {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final record = HabitRecord(
        habitId: habitId,
        date: date,
        status: HabitStatus.complete,
        note: 'Felt great today!',
      );

      final id = await dbHelper.insertHabitRecord(record);

      expect(id, greaterThan(0));

      final retrieved = await dbHelper.getHabitRecord(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.habitId, equals(habitId));
      expect(retrieved.date, equals(date));
      expect(retrieved.status, equals(HabitStatus.complete));
      expect(retrieved.note, equals('Felt great today!'));
    });

    test('Get habit record by date - should find correct record', () async {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await dbHelper.insertHabitRecord(HabitRecord(
        habitId: habitId,
        date: date,
        status: HabitStatus.complete,
      ));

      final record = await dbHelper.getHabitRecordByDate(habitId, date);

      expect(record, isNotNull);
      expect(record!.habitId, equals(habitId));
      expect(record.date, equals(date));
    });

    test('Get habit record by date - should return null for non-existent date',
        () async {
      final record = await dbHelper.getHabitRecordByDate(habitId, '2020-01-01');
      expect(record, isNull);
    });

    test(
        'Get habit records - should return all records for habit ordered by date DESC',
        () async {
      final today = DateTime.now();

      // Insert records in non-sequential order
      await dbHelper.insertHabitRecord(HabitRecord(
        habitId: habitId,
        date: DateFormat('yyyy-MM-dd')
            .format(today.subtract(const Duration(days: 2))),
        status: HabitStatus.complete,
      ));

      await dbHelper.insertHabitRecord(HabitRecord(
        habitId: habitId,
        date: DateFormat('yyyy-MM-dd').format(today),
        status: HabitStatus.missed,
      ));

      await dbHelper.insertHabitRecord(HabitRecord(
        habitId: habitId,
        date: DateFormat('yyyy-MM-dd')
            .format(today.subtract(const Duration(days: 1))),
        status: HabitStatus.skipped,
      ));

      final records = await dbHelper.getHabitRecords(habitId);

      expect(records.length, equals(3));

      // Verify descending order (most recent first)
      expect(records[0].date, equals(DateFormat('yyyy-MM-dd').format(today)));
      expect(
          records[1].date,
          equals(DateFormat('yyyy-MM-dd')
              .format(today.subtract(const Duration(days: 1)))));
      expect(
          records[2].date,
          equals(DateFormat('yyyy-MM-dd')
              .format(today.subtract(const Duration(days: 2)))));
    });

    test('Update habit record - should modify existing record', () async {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final id = await dbHelper.insertHabitRecord(HabitRecord(
        habitId: habitId,
        date: date,
        status: HabitStatus.complete,
      ));

      final updatedRecord = HabitRecord(
        id: id,
        habitId: habitId,
        date: date,
        status: HabitStatus.missed,
        note: 'Changed my mind',
      );

      await dbHelper.updateHabitRecord(updatedRecord);
      final retrieved = await dbHelper.getHabitRecord(id);

      expect(retrieved!.status, equals(HabitStatus.missed));
      expect(retrieved.note, equals('Changed my mind'));
    });

    test('Delete habit record - should remove record', () async {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final id = await dbHelper.insertHabitRecord(HabitRecord(
        habitId: habitId,
        date: date,
        status: HabitStatus.complete,
      ));

      await dbHelper.deleteHabitRecord(id);
      final retrieved = await dbHelper.getHabitRecord(id);

      expect(retrieved, isNull);
    });

    test('Multiple habits - records should be isolated per habit', () async {
      final habit1Id = habitId;
      final habit2Id = await dbHelper.insertHabit(Habit(
        name: 'Second Habit',
        createdAt: DateTime.now().toIso8601String(),
      ));

      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await dbHelper.insertHabitRecord(HabitRecord(
        habitId: habit1Id,
        date: date,
        status: HabitStatus.complete,
      ));

      await dbHelper.insertHabitRecord(HabitRecord(
        habitId: habit2Id,
        date: date,
        status: HabitStatus.missed,
      ));

      final habit1Records = await dbHelper.getHabitRecords(habit1Id);
      final habit2Records = await dbHelper.getHabitRecords(habit2Id);

      expect(habit1Records.length, equals(1));
      expect(habit2Records.length, equals(1));
      expect(habit1Records.first.status, equals(HabitStatus.complete));
      expect(habit2Records.first.status, equals(HabitStatus.missed));
    });
  });

  group('Data Integrity and Constraints', () {
    test(
        'Foreign key constraint - deleting habit should cascade delete records',
        () async {
      final habitId = await dbHelper.insertHabit(Habit(
        name: 'Test Habit',
        createdAt: DateTime.now().toIso8601String(),
      ));

      // Insert records
      await dbHelper.insertHabitRecord(HabitRecord(
        habitId: habitId,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        status: HabitStatus.complete,
      ));

      // Delete habit
      await dbHelper.deleteHabitPermanently(habitId);

      // Records should be gone
      final records = await dbHelper.getHabitRecords(habitId);
      expect(records, isEmpty);
    });

    test('Soft delete - isDeleted flag should work correctly', () async {
      final habitId = await dbHelper.insertHabit(Habit(
        name: 'To Soft Delete',
        createdAt: DateTime.now().toIso8601String(),
      ));

      // Soft delete
      final habit = await dbHelper.getHabit(habitId);
      await dbHelper.updateHabit(habit!.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now().toIso8601String(),
      ));

      // Should not appear in active habits
      final activeHabits = await dbHelper.getAllHabits(includeDeleted: false);
      expect(activeHabits.any((h) => h.id == habitId), isFalse);

      // Should appear in all habits
      final allHabits = await dbHelper.getAllHabits(includeDeleted: true);
      expect(allHabits.any((h) => h.id == habitId), isTrue);
    });

    test('Date handling - dates should be stored in ISO8601 format', () async {
      final now = DateTime.now();
      final habit = Habit(
        name: 'Date Test',
        createdAt: now.toIso8601String(),
      );

      final id = await dbHelper.insertHabit(habit);
      final retrieved = await dbHelper.getHabit(id);

      expect(retrieved!.createdAt, equals(now.toIso8601String()));

      // Verify it can be parsed back
      final parsedDate = DateTime.parse(retrieved.createdAt);
      expect(parsedDate.year, equals(now.year));
      expect(parsedDate.month, equals(now.month));
      expect(parsedDate.day, equals(now.day));
    });
  });

  group('Edge Cases and Error Handling', () {
    test('Insert habit with very long name - should handle gracefully',
        () async {
      final longName = 'A' * 1000;
      final habit = Habit(
        name: longName,
        createdAt: DateTime.now().toIso8601String(),
      );

      final id = await dbHelper.insertHabit(habit);
      final retrieved = await dbHelper.getHabit(id);

      expect(retrieved!.name, equals(longName));
    });

    test('Insert habit record with very long note - should handle gracefully',
        () async {
      final habitId = await dbHelper.insertHabit(Habit(
        name: 'Test',
        createdAt: DateTime.now().toIso8601String(),
      ));

      final longNote = 'B' * 5000;
      final record = HabitRecord(
        habitId: habitId,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        status: HabitStatus.complete,
        note: longNote,
      );

      final id = await dbHelper.insertHabitRecord(record);
      final retrieved = await dbHelper.getHabitRecord(id);

      expect(retrieved!.note, equals(longNote));
    });

    test('Query non-existent habit records - should return empty list',
        () async {
      final records = await dbHelper.getHabitRecords(99999);
      expect(records, isEmpty);
    });

    test('Delete non-existent habit - should not throw error', () async {
      final result = await dbHelper.deleteHabitPermanently(99999);
      expect(result, equals(0)); // 0 rows affected
    });

    test('Delete non-existent habit record - should not throw error', () async {
      final result = await dbHelper.deleteHabitRecord(99999);
      expect(result, equals(0)); // 0 rows affected
    });

    test('Null note in habit record - should be stored as null', () async {
      final habitId = await dbHelper.insertHabit(Habit(
        name: 'Test',
        createdAt: DateTime.now().toIso8601String(),
      ));

      final record = HabitRecord(
        habitId: habitId,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        status: HabitStatus.complete,
        note: null,
      );

      final id = await dbHelper.insertHabitRecord(record);
      final retrieved = await dbHelper.getHabitRecord(id);

      expect(retrieved!.note, isNull);
    });
  });

  group('Performance and Indexing', () {
    test('Large dataset - should handle many habits efficiently', () async {
      final stopwatch = Stopwatch()..start();

      // Insert 100 habits
      for (int i = 0; i < 100; i++) {
        await dbHelper.insertHabit(Habit(
          name: 'Habit $i',
          createdAt: DateTime.now().toIso8601String(),
        ));
      }

      stopwatch.stop();

      // Should complete in reasonable time (< 2 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));

      final habits = await dbHelper.getAllHabits();
      expect(habits.length, greaterThanOrEqualTo(100));
    });

    test('Large dataset - should handle many records efficiently', () async {
      final habitId = await dbHelper.insertHabit(Habit(
        name: 'Test Habit',
        createdAt: DateTime.now().toIso8601String(),
      ));

      final stopwatch = Stopwatch()..start();

      // Insert 365 records (one year of data)
      for (int i = 0; i < 365; i++) {
        await dbHelper.insertHabitRecord(HabitRecord(
          habitId: habitId,
          date: DateFormat('yyyy-MM-dd')
              .format(DateTime.now().subtract(Duration(days: i))),
          status: i % 3 == 0
              ? HabitStatus.complete
              : i % 3 == 1
                  ? HabitStatus.missed
                  : HabitStatus.skipped,
        ));
      }

      stopwatch.stop();

      // Should complete in reasonable time (< 3 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));

      final records = await dbHelper.getHabitRecords(habitId);
      expect(records.length, equals(365));
    });

    test('Index effectiveness - querying by habitId should be fast', () async {
      final habitId = await dbHelper.insertHabit(Habit(
        name: 'Test Habit',
        createdAt: DateTime.now().toIso8601String(),
      ));

      // Insert 100 records
      for (int i = 0; i < 100; i++) {
        await dbHelper.insertHabitRecord(HabitRecord(
          habitId: habitId,
          date: DateFormat('yyyy-MM-dd')
              .format(DateTime.now().subtract(Duration(days: i))),
          status: HabitStatus.complete,
        ));
      }

      final stopwatch = Stopwatch()..start();

      // Query records 10 times
      for (int i = 0; i < 10; i++) {
        await dbHelper.getHabitRecords(habitId);
      }

      stopwatch.stop();

      // Should be very fast thanks to index (< 100ms for 10 queries)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });
}
