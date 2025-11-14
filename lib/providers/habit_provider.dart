import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../models/habit_record.dart';
import '../models/habit_manager.dart';

/// Provider class for managing habit state across the app
///
/// This class uses ChangeNotifier to notify listeners when data changes,
/// eliminating the need for manual setState() calls in widgets.
class HabitProvider extends ChangeNotifier {
  final HabitManager _habitManager = HabitManager();

  // State
  List<Habit> _habits = [];
  List<Habit> _deletedHabits = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<int, int> _currentStreakCache = {};
  final Map<int, Map<String, dynamic>> _statsCache = {};

  // Getters
  List<Habit> get habits => _habits;
  List<Habit> get deletedHabits => _deletedHabits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasHabits => _habits.isNotEmpty;
  int currentStreakFor(int habitId) => _currentStreakCache[habitId] ?? 0;

  /// Load all habits from database
  Future<void> loadHabits() async {
    _setLoading(true);
    _clearError();

    try {
      _habits = await _habitManager.loadHabits();
      final streakEntries = await Future.wait(
        _habits
            .where((habit) => habit.id != null)
            .map((habit) async => MapEntry(
                  habit.id!,
                  await _habitManager.getCurrentStreak(habit.id!),
                )),
      );
      _currentStreakCache
        ..clear()
        ..addEntries(streakEntries);
      _statsCache.clear();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load habits: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new habit
  Future<bool> addHabit(String name) async {
    _clearError();

    try {
      await _habitManager.addHabit(name);
      await loadHabits(); // Reload all habits
      return true;
    } catch (e) {
      _setError('Failed to add habit: $e');
      return false;
    }
  }

  /// Update an existing habit
  Future<bool> updateHabit(Habit habit) async {
    _clearError();

    try {
      await _habitManager.updateHabit(habit);
      await loadHabits(); // Reload all habits
      return true;
    } catch (e) {
      _setError('Failed to update habit: $e');
      return false;
    }
  }

  /// Soft delete habits (move to trash)
  Future<bool> deleteHabits(List<int> habitIds) async {
    _clearError();

    try {
      for (final id in habitIds) {
        await _habitManager.deleteHabit(id);
      }
      await loadHabits(); // Reload all habits
      return true;
    } catch (e) {
      _setError('Failed to delete habits: $e');
      return false;
    }
  }

  /// Load deleted habits (for trash screen)
  Future<void> loadDeletedHabits() async {
    _setLoading(true);
    _clearError();

    try {
      _deletedHabits = await _habitManager.loadDeletedHabits();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load deleted habits: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Restore a habit from trash
  Future<bool> restoreHabit(int habitId) async {
    _clearError();

    try {
      await _habitManager.restoreHabit(habitId);
      await loadHabits(); // Reload all habits
      await loadDeletedHabits(); // Reload deleted habits
      return true;
    } catch (e) {
      _setError('Failed to restore habit: $e');
      return false;
    }
  }

  /// Permanently delete a habit
  Future<bool> permanentlyDeleteHabit(int habitId) async {
    _clearError();

    try {
      await _habitManager.permanentlyDeleteHabit(habitId);
      _currentStreakCache.remove(habitId);
      _statsCache.remove(habitId);
      await loadDeletedHabits(); // Reload deleted habits
      return true;
    } catch (e) {
      _setError('Failed to permanently delete habit: $e');
      return false;
    }
  }

  /// Get records for a specific habit
  Future<List<HabitRecord>> getRecordsForHabit(int habitId) async {
    try {
      return await _habitManager.getRecordsForHabit(habitId);
    } catch (e) {
      _setError('Failed to load records: $e');
      return [];
    }
  }

  /// Get current streak for a habit
  Future<int> getCurrentStreak(int habitId) async {
    try {
      if (_currentStreakCache.containsKey(habitId)) {
        return _currentStreakCache[habitId]!;
      }
      final streak = await _habitManager.getCurrentStreak(habitId);
      _currentStreakCache[habitId] = streak;
      return streak;
    } catch (e) {
      _setError('Failed to calculate streak: $e');
      return 0;
    }
  }

  /// Save or update a habit record
  Future<bool> addOrUpdateRecord(
    int habitId,
    DateTime date,
    HabitStatus status, {
    String? note,
  }) async {
    _clearError();

    try {
      await _habitManager.addOrUpdateRecord(habitId, date, status, note: note);
      // Don't reload all habits, just notify that data changed
      _statsCache.remove(habitId);
      _currentStreakCache[habitId] =
          await _habitManager.getCurrentStreak(habitId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to save record: $e');
      return false;
    }
  }

  /// Delete a habit record
  Future<bool> deleteRecord(int recordId) async {
    _clearError();

    try {
      final removedRecord = await _habitManager.deleteRecord(recordId);
      if (removedRecord != null) {
        _statsCache.remove(removedRecord.habitId);
        _currentStreakCache[removedRecord.habitId] =
            await _habitManager.getCurrentStreak(removedRecord.habitId);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete record: $e');
      return false;
    }
  }

  /// Get statistics for a habit
  Future<Map<String, dynamic>> getHabitStatistics(int habitId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _statsCache.containsKey(habitId)) {
      return Map<String, dynamic>.from(_statsCache[habitId]!);
    }
    try {
      final stats = await _habitManager.getHabitStatistics(habitId);
      _statsCache[habitId] = Map<String, dynamic>.from(stats);
      return stats;
    } catch (e) {
      _setError('Failed to calculate statistics: $e');
      return {};
    }
  }

  /// Get record for specific date
  Future<HabitRecord?> getRecordForDate(int habitId, DateTime date) async {
    try {
      return await _habitManager.getRecordForDate(habitId, date);
    } catch (e) {
      _setError('Failed to load record: $e');
      return null;
    }
  }

  /// Get max streak for a habit
  Future<int> getMaxStreak(int habitId) async {
    try {
      return await _habitManager.getMaxStreak(habitId);
    } catch (e) {
      _setError('Failed to calculate max streak: $e');
      return 0;
    }
  }

  /// Get a single habit by ID
  Habit? getHabitById(int id) {
    try {
      return _habits.firstWhere((habit) => habit.id == id);
    } catch (e) {
      return null;
    }
  }

  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Clear error message
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
