import 'package:intl/intl.dart';
import 'daily_record.dart';
import 'database_helper.dart'; // Import the database helper

class DailyRecordManager {
  int currentStreak = 0;
  int maxStreak = 0;
  int activeDays = 0;
  List<DailyRecord> _records = [];

  List<DailyRecord> get records => _records;

  final dbHelper = DatabaseHelper.instance; // Instance of the helper

  Future<void> loadRecords() async {
    final allRows = await dbHelper.getRecords();
    _records = allRows
        .map((row) => DailyRecord(
            date: DateTime.parse(row['date'] as String),
            isSuccess: (row['isSuccess'] as int) == 1))
        .toList();
    updateStreaks();
  }

  Future<void> deleteRecord(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    await dbHelper.deleteRecord(formattedDate);
    await loadRecords(); // Reload from the database
  }

  Future<void> addRecord(DateTime date, bool wasSuccessful) async {
    if (date.isAfter(DateTime.now())) {
      throw Exception("Cannot add records for future dates.");
    }
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    // Check if record already exists
    if (hasRecordForDate(date)) {
      // Update existing record
      await dbHelper.updateRecord({
        'date': formattedDate,
        'isSuccess': wasSuccessful ? 1 : 0,
      });
    } else {
      // Insert new record
      await dbHelper.insertRecord({
        'date': formattedDate,
        'isSuccess': wasSuccessful ? 1 : 0,
      });
    }
    await loadRecords(); // Reload from the database
  }

  Future<void> editRecord(DateTime date, bool wasSuccessful) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    await dbHelper.updateRecord({
      'date': formattedDate,
      'isSuccess': wasSuccessful ? 1 : 0,
    });
    await loadRecords(); // Reload from the database
  }

  bool hasRecordForDate(DateTime date) {
    return _records.any((r) => isSameDay(r.date, date));
  }

  void updateStreaks() {
    _records.sort((a, b) => a.date.compareTo(b.date));
    activeDays = _records.length;

    int tempStreak = 0;
    int tempMaxStreak = 0;
    DateTime? lastSuccessfulDate;

    DateTime today = DateTime.now(); // Get current date and time
    DateTime todayMidnight = DateTime(
        today.year, today.month, today.day); // Get today's date at midnight

    for (var record in _records) {
      if (record.isSuccess) {
        if (lastSuccessfulDate == null) {
          tempStreak = 1;
        } else {
          final difference = record.date.difference(lastSuccessfulDate).inDays;
          if (difference <= 1) {
            // Consecutive or same day
            tempStreak += 1;
          } else {
            tempStreak = 1; // Streak broken
          }
        }
        lastSuccessfulDate = record.date;
        if (tempStreak > tempMaxStreak) {
          tempMaxStreak = tempStreak;
        }
      } else {
        tempStreak = 0; // Reset on failure
        lastSuccessfulDate = record.date;
      }
    }

    // Check if the last successful date was yesterday
    if (lastSuccessfulDate != null &&
        lastSuccessfulDate.isBefore(todayMidnight)) {
      // If the last successful date was yesterday, and today is after midnight, continue the streak.
      if (today.difference(lastSuccessfulDate).inDays <= 1)
        currentStreak = tempStreak;
      else
        currentStreak = 0;
    } else
      currentStreak = tempStreak;

    maxStreak = tempMaxStreak;
  }

  // Helper function to compare dates without time
  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) {
      return false; // Or throw an error, depending on your needs
    }
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
