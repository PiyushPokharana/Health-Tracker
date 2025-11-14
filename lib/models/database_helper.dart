import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'habit.dart';
import 'habit_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "habit_tracker.db");
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Habits (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isDeleted INTEGER NOT NULL DEFAULT 0,
        deletedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE HabitRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (habitId) REFERENCES Habits (id) ON DELETE CASCADE,
        UNIQUE(habitId, date)
      )
    ''');

    await db.execute('CREATE INDEX idx_habitId ON HabitRecords(habitId)');
    await db.execute('CREATE INDEX idx_date ON HabitRecords(date)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrate from version 1 (DailyRecords) to version 2 (Habits + HabitRecords)

      // Create new tables
      await db.execute('''
        CREATE TABLE Habits (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          createdAt TEXT NOT NULL,
          isDeleted INTEGER NOT NULL DEFAULT 0,
          deletedAt TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE HabitRecords (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          habitId INTEGER NOT NULL,
          date TEXT NOT NULL,
          status TEXT NOT NULL,
          note TEXT,
          FOREIGN KEY (habitId) REFERENCES Habits (id) ON DELETE CASCADE,
          UNIQUE(habitId, date)
        )
      ''');

      await db.execute('CREATE INDEX idx_habitId ON HabitRecords(habitId)');
      await db.execute('CREATE INDEX idx_date ON HabitRecords(date)');

      final hasLegacyTable = await _tableExists(db, 'DailyRecords');
      if (hasLegacyTable) {
        // Migrate old data: Create a default "Daily Success" habit
        final habitId = await db.insert('Habits', {
          'name': 'Daily Success',
          'createdAt': DateTime.now().toIso8601String(),
          'isDeleted': 0,
          'deletedAt': null,
        });

        // Migrate all old records to the new habit
        final oldRecords = await db.query('DailyRecords');
        for (var record in oldRecords) {
          await db.insert('HabitRecords', {
            'habitId': habitId,
            'date': record['date'],
            'status': (record['isSuccess'] == 1) ? 'complete' : 'missed',
            'note': null,
          });
        }

        // Drop old table
        await db.execute('DROP TABLE IF EXISTS DailyRecords');
      }
    }
  }

  Future<bool> _tableExists(Database db, String tableName) async {
    final result = await db.rawQuery(
      'SELECT name FROM sqlite_master WHERE type = ? AND name = ?',
      ['table', tableName],
    );
    return result.isNotEmpty;
  }

  // ==================== HABIT CRUD OPERATIONS ====================

  Future<int> insertHabit(Habit habit) async {
    final db = await database;
    return await db.insert('Habits', habit.toMap());
  }

  Future<Habit?> getHabit(int id) async {
    final db = await database;
    final maps = await db.query(
      'Habits',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }

  Future<List<Habit>> getAllHabits({bool includeDeleted = false}) async {
    final db = await database;
    final maps = includeDeleted
        ? await db.query('Habits')
        : await db.query('Habits', where: 'isDeleted = 0');
    return maps.map((map) => Habit.fromMap(map)).toList();
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await database;
    return await db.update(
      'Habits',
      habit.toMap(),
      where: 'id = ?',
      whereArgs: [habit.id],
    );
  }

  Future<int> deleteHabitPermanently(int id) async {
    final db = await database;
    // Delete all associated records first
    await db.delete('HabitRecords', where: 'habitId = ?', whereArgs: [id]);
    // Then delete the habit
    return await db.delete('Habits', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== HABIT RECORD CRUD OPERATIONS ====================

  Future<int> insertHabitRecord(HabitRecord record) async {
    final db = await database;
    return await db.insert('HabitRecords', record.toMap());
  }

  Future<HabitRecord?> getHabitRecord(int id) async {
    final db = await database;
    final maps = await db.query(
      'HabitRecords',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return HabitRecord.fromMap(maps.first);
  }

  Future<HabitRecord?> getHabitRecordByDate(int habitId, String date) async {
    final db = await database;
    final maps = await db.query(
      'HabitRecords',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, date],
    );
    if (maps.isEmpty) return null;
    return HabitRecord.fromMap(maps.first);
  }

  Future<List<HabitRecord>> getHabitRecords(int habitId) async {
    final db = await database;
    final maps = await db.query(
      'HabitRecords',
      where: 'habitId = ?',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => HabitRecord.fromMap(map)).toList();
  }

  Future<int> updateHabitRecord(HabitRecord record) async {
    final db = await database;
    return await db.update(
      'HabitRecords',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  Future<int> deleteHabitRecord(int id) async {
    final db = await database;
    return await db.delete('HabitRecords', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== OLD METHODS (Kept for backward compatibility) ====================

  Future<int> insertRecord(Map<String, dynamic> record) async {
    final db = await instance.database;
    return await db.insert('DailyRecords', record);
  }

  Future<List<Map<String, dynamic>>> getRecords() async {
    final db = await instance.database;
    return await db.query('DailyRecords');
  }

  Future<int> updateRecord(Map<String, dynamic> record) async {
    final db = await instance.database;
    return await db.update(
      'DailyRecords',
      record,
      where: 'date = ?',
      whereArgs: [record['date']],
    );
  }

  Future<int> deleteRecord(String date) async {
    final db = await instance.database;
    return await db.delete(
      'DailyRecords',
      where: 'date = ?',
      whereArgs: [date],
    );
  }
}
