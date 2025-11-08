import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;

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
    String path = join(documentsDirectory.path, "daily_records.db");
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE DailyRecords (
        date TEXT PRIMARY KEY,
        isSuccess INTEGER
      )
    ''');
  }

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
