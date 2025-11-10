import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/habit.dart';
import '../models/habit_record.dart';
import '../models/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Export all habits and records to a JSON file
  Future<Map<String, dynamic>> exportData() async {
    try {
      // Get all habits (excluding deleted ones)
      final habits = await _dbHelper.getAllHabits(includeDeleted: false);

      // Get all records for each habit
      List<Map<String, dynamic>> habitsData = [];

      for (var habit in habits) {
        final records = await _dbHelper.getHabitRecords(habit.id!);

        habitsData.add({
          'habit': habit.toMap(),
          'records': records.map((r) => r.toMap()).toList(),
        });
      } // Create backup data structure
      final backupData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'habitsCount': habits.length,
        'data': habitsData,
      };

      return backupData;
    } catch (e) {
      debugPrint('Error exporting data: $e');
      rethrow;
    }
  }

  /// Save backup data to a file and share it
  Future<String> saveAndShareBackup() async {
    try {
      // Get export data
      final backupData = await exportData();

      // Convert to JSON
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'habit_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      // Write to file
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Habit Tracker Backup',
        text:
            'My habit tracking data backup from ${DateTime.now().toString().split('.')[0]}',
      );

      return file.path;
    } catch (e) {
      debugPrint('Error saving and sharing backup: $e');
      rethrow;
    }
  }

  /// Import data from a JSON file
  Future<Map<String, dynamic>> importData(String filePath) async {
    try {
      // Read file
      final file = File(filePath);
      final jsonString = await file.readAsString();

      // Parse JSON
      final Map<String, dynamic> backupData = json.decode(jsonString);

      // Validate backup structure
      if (!backupData.containsKey('version') ||
          !backupData.containsKey('data')) {
        throw Exception('Invalid backup file format');
      }

      final List<dynamic> habitsData = backupData['data'];
      int habitsImported = 0;
      int recordsImported = 0;
      int habitsDuplicate = 0;

      // Import each habit and its records
      for (var habitData in habitsData) {
        final habitMap = habitData['habit'] as Map<String, dynamic>;
        final recordsList = habitData['records'] as List<dynamic>;

        // Check if habit already exists (by name)
        final existingHabits =
            await _dbHelper.getAllHabits(includeDeleted: false);
        final existingHabit =
            existingHabits.where((h) => h.name == habitMap['name']).firstOrNull;

        int habitId;

        if (existingHabit != null) {
          // Habit already exists, use existing ID
          habitId = existingHabit.id!;
          habitsDuplicate++;
        } else {
          // Create new habit (without ID to let DB auto-generate)
          final newHabit = Habit(
            name: habitMap['name'],
            createdAt: habitMap['createdAt'] as String,
            isDeleted: (habitMap['isDeleted'] ?? 0) == 1,
            deletedAt: habitMap['deletedAt'] as String?,
          );

          habitId = await _dbHelper.insertHabit(newHabit);
          habitsImported++;
        }

        // Import records for this habit
        for (var recordMap in recordsList) {
          final record = HabitRecord.fromMap(recordMap);

          // Check if record already exists
          final existingRecord = await _dbHelper.getHabitRecordByDate(
            habitId,
            record.date,
          );

          if (existingRecord == null) {
            // Create new record with updated habit ID
            final newRecord = HabitRecord(
              habitId: habitId,
              date: record.date,
              status: record.status,
              note: record.note,
            );

            await _dbHelper.insertHabitRecord(newRecord);
            recordsImported++;
          }
        }
      }

      return {
        'success': true,
        'habitsImported': habitsImported,
        'habitsDuplicate': habitsDuplicate,
        'recordsImported': recordsImported,
        'totalHabits': habitsData.length,
      };
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    }
  }

  /// Pick a backup file and import it
  Future<Map<String, dynamic>> pickAndImportBackup() async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Backup File',
      );

      if (result == null || result.files.single.path == null) {
        throw Exception('No file selected');
      }

      // Import from selected file
      return await importData(result.files.single.path!);
    } catch (e) {
      debugPrint('Error picking and importing backup: $e');
      rethrow;
    }
  }
}
