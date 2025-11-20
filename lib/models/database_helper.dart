import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'habit.dart';
import 'habit_record.dart';
import 'habit_session.dart';

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
      version: 3,
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
        deletedAt TEXT,
        timerEnabled INTEGER NOT NULL DEFAULT 0,
        allowMultipleSessions INTEGER NOT NULL DEFAULT 0
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS HabitSessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        habitId INTEGER NOT NULL,
        startTs INTEGER NOT NULL,
        endTs INTEGER,
        status TEXT,
        note TEXT,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (habitId) REFERENCES Habits (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sessions_habitId ON HabitSessions(habitId)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sessions_startTs ON HabitSessions(startTs)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sessions_habit_start ON HabitSessions(habitId, startTs)');
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
          deletedAt TEXT,
          timerEnabled INTEGER NOT NULL DEFAULT 0,
          allowMultipleSessions INTEGER NOT NULL DEFAULT 0
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
        // Backup legacy table first
        final ts = DateTime.now().millisecondsSinceEpoch;
        await db.execute(
            'CREATE TABLE IF NOT EXISTS backup_DailyRecords_$ts AS SELECT * FROM DailyRecords');

        // Migrate old data: Create a default "Daily Success" habit
        final habitId = await db.insert('Habits', {
          'name': 'Daily Success',
          'createdAt': DateTime.now().toIso8601String(),
          'isDeleted': 0,
          'deletedAt': null,
          'timerEnabled': 0,
          'allowMultipleSessions': 0,
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
        // Do NOT drop legacy table here; keep for verification
      }
    }

    if (oldVersion < 3) {
      // Add missing columns to Habits, create HabitSessions and indexes
      // Add columns if not present
      final habitColumns = await db.rawQuery('PRAGMA table_info(Habits)');
      final hasTimerEnabled =
          habitColumns.any((c) => (c['name'] as String?) == 'timerEnabled');
      final hasAllowMulti = habitColumns
          .any((c) => (c['name'] as String?) == 'allowMultipleSessions');
      if (!hasTimerEnabled) {
        await db.execute(
            'ALTER TABLE Habits ADD COLUMN timerEnabled INTEGER NOT NULL DEFAULT 0');
      }
      if (!hasAllowMulti) {
        await db.execute(
            'ALTER TABLE Habits ADD COLUMN allowMultipleSessions INTEGER NOT NULL DEFAULT 0');
      }

      // Create HabitSessions table if missing
      final hasSessions = await _tableExists(db, 'HabitSessions');
      if (!hasSessions) {
        await db.execute('''
          CREATE TABLE HabitSessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habitId INTEGER NOT NULL,
            startTs INTEGER NOT NULL,
            endTs INTEGER,
            status TEXT,
            note TEXT,
            createdAt INTEGER NOT NULL,
            FOREIGN KEY (habitId) REFERENCES Habits (id) ON DELETE CASCADE
          )
        ''');
      }
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sessions_habitId ON HabitSessions(habitId)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sessions_startTs ON HabitSessions(startTs)');
      await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_sessions_habit_start ON HabitSessions(habitId, startTs)');
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

  // ==================== HABIT SESSION CRUD OPERATIONS ====================

  Future<int> createSession({
    required int habitId,
    required int startTs,
    String? status,
    String? note,
    int? createdAt,
  }) async {
    final db = await database;
    final session = HabitSession(
      habitId: habitId,
      startTs: startTs,
      endTs: null,
      status: status,
      note: note,
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch,
    );
    return await db.insert('HabitSessions', session.toMap());
  }

  Future<int> endSession({
    required int sessionId,
    required int endTs,
  }) async {
    final db = await database;
    return await db.update(
      'HabitSessions',
      {'endTs': endTs},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<HabitSession?> getRunningSession(int habitId) async {
    final db = await database;
    final maps = await db.query(
      'HabitSessions',
      where: 'habitId = ? AND endTs IS NULL',
      whereArgs: [habitId],
      orderBy: 'startTs DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HabitSession.fromMap(maps.first);
  }

  Future<HabitSession?> getSession(int id) async {
    final db = await database;
    final maps = await db.query(
      'HabitSessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return HabitSession.fromMap(maps.first);
  }

  Future<List<HabitSession>> getSessionsForDay(
      int habitId, DateTime day) async {
    final db = await database;
    final startOfDay =
        DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;
    final maps = await db.query(
      'HabitSessions',
      where: 'habitId = ? AND startTs >= ? AND startTs <= ?',
      whereArgs: [habitId, startOfDay, endOfDay],
      orderBy: 'startTs DESC',
    );
    return maps.map((m) => HabitSession.fromMap(m)).toList();
  }

  Future<int> updateSession(HabitSession session) async {
    final db = await database;
    return await db.update(
      'HabitSessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await database;
    return await db.delete('HabitSessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllSessionsForHabit(int habitId) async {
    final db = await database;
    return await db
        .delete('HabitSessions', where: 'habitId = ?', whereArgs: [habitId]);
  }

  // ==================== BULK QUERIES ====================

  Future<List<HabitRecord>> getHabitRecordsInRange(
      String startDateInclusive, String endDateInclusive) async {
    final db = await database;
    final maps = await db.query(
      'HabitRecords',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDateInclusive, endDateInclusive],
    );
    return maps.map((m) => HabitRecord.fromMap(m)).toList();
  }

  Future<List<HabitSession>> getAllRunningSessions() async {
    final db = await database;
    final maps = await db.query(
      'HabitSessions',
      where: 'endTs IS NULL',
      orderBy: 'startTs DESC',
    );
    return maps.map((m) => HabitSession.fromMap(m)).toList();
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
