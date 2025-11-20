import 'package:flutter/foundation.dart';
import '../models/habit.dart';
import '../models/habit_record.dart';
import '../models/habit_manager.dart';
import '../models/habit_session.dart';

/// Provider class for managing habit state across the app
///
/// This class uses ChangeNotifier to notify listeners when data changes,
/// eliminating the need for manual setState() calls in widgets.
class HabitProvider extends ChangeNotifier {
  static const Duration _timerAnomalyThreshold = Duration(hours: 12);

  HabitProvider({HabitManager? habitManager})
      : _habitManager = habitManager ?? HabitManager();

  final HabitManager _habitManager;

  // State
  List<Habit> _habits = [];
  List<Habit> _deletedHabits = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<int, int> _currentStreakCache = {};
  final Map<int, Map<String, dynamic>> _statsCache = {};
  final Map<int, HabitSession> _runningSessions = {};
  final Map<int, Map<String, List<HabitSession>>> _sessionsByDayCache = {};
  final Set<int> _pausedHabits = {};
  final Map<int, List<HabitStatus>> _recentStatusByHabit = {};
  final Set<int> _restoredSessionHabits = {};
  final Set<int> _sessionAnomalyHabits = {};

  // Getters
  List<Habit> get habits => _habits;
  List<Habit> get deletedHabits => _deletedHabits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasHabits => _habits.isNotEmpty;
  int currentStreakFor(int habitId) => _currentStreakCache[habitId] ?? 0;
  HabitSession? runningSessionFor(int habitId) => _runningSessions[habitId];
  bool isPaused(int habitId) => _pausedHabits.contains(habitId);
  List<HabitStatus>? recentStatusFor(int habitId) =>
      _recentStatusByHabit[habitId];
  bool wasSessionRestored(int habitId) =>
      _restoredSessionHabits.contains(habitId);
  bool hasTimerAnomaly(int habitId) => _sessionAnomalyHabits.contains(habitId);

  Duration elapsedDurationFor(int habitId, {int? referenceMillis}) {
    final session = _runningSessions[habitId];
    if (session == null) return Duration.zero;
    final reference = session.endTs ??
        referenceMillis ??
        DateTime.now().millisecondsSinceEpoch;
    final elapsed = reference - session.startTs;
    if (elapsed <= 0) {
      return Duration.zero;
    }
    return Duration(milliseconds: elapsed);
  }

  /// Initialize provider: load habits and restore running sessions
  Future<void> init() async {
    await loadHabits();
    await _restoreRunningSessions();
    await computeRecentSeries();
  }

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

  /// Alias: load all habits (kept for API clarity per plan)
  Future<void> loadAllHabits() => loadHabits();

  /// Load habits and compute streaks in one pass (currently same as loadHabits)
  Future<void> loadHabitsWithStreaks() => loadHabits();

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

  // ==================== SESSION/TIMER METHODS ====================

  Future<bool> startTimer(int habitId) async {
    _clearError();
    try {
      final habit = getHabitById(habitId);
      if (habit == null) {
        _setError('Habit not found');
        return false;
      }
      final allowMulti = habit.allowMultipleSessions;
      if (!allowMulti && _runningSessions.containsKey(habitId)) {
        // One running session allowed for this habit in single-session mode
        return true;
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      final sessionId = await _habitManager.createSession(
        habitId: habitId,
        startTs: now,
      );
      _runningSessions[habitId] = HabitSession(
        id: sessionId,
        habitId: habitId,
        startTs: now,
        createdAt: now,
      );
      _pausedHabits.remove(habitId);
      _restoredSessionHabits.remove(habitId);
      _sessionAnomalyHabits.remove(habitId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to start timer: $e');
      return false;
    }
  }

  Future<bool> pauseTimer(int habitId) async {
    // Pause is in-memory only; session remains open
    if (!_runningSessions.containsKey(habitId)) return false;
    _pausedHabits.add(habitId);
    notifyListeners();
    return true;
  }

  Future<bool> resumeTimer(int habitId) async {
    // Resume a paused in-memory session; no DB change
    if (!_runningSessions.containsKey(habitId)) return false;
    if (!_pausedHabits.contains(habitId)) return true;
    _pausedHabits.remove(habitId);
    notifyListeners();
    return true;
  }

  Future<bool> stopTimer(int habitId, {DateTime? endTime}) async {
    _clearError();
    try {
      final session = _runningSessions[habitId];
      if (session == null || session.id == null) return false;
      final customEnd = endTime?.millisecondsSinceEpoch ??
          DateTime.now().millisecondsSinceEpoch;
      final resolvedEnd =
          customEnd <= session.startTs ? session.startTs + 1000 : customEnd;
      await _habitManager.endSession(
        sessionId: session.id!,
        endTs: resolvedEnd,
      );
      _runningSessions.remove(habitId);
      _pausedHabits.remove(habitId);
      _restoredSessionHabits.remove(habitId);
      _sessionAnomalyHabits.remove(habitId);
      // Invalidate day cache for today
      final key = _dateKey(DateTime.now());
      _sessionsByDayCache[habitId]?.remove(key);
      await computeRecentSeries();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to stop timer: $e');
      return false;
    }
  }

  Future<List<HabitSession>> getSessionsForDay(
      int habitId, DateTime date) async {
    final key = _dateKey(date);
    final cacheForHabit = _sessionsByDayCache[habitId] ??= {};
    if (cacheForHabit.containsKey(key)) {
      return cacheForHabit[key]!;
    }
    try {
      final sessions = await _habitManager.getSessionsForDay(habitId, date);
      cacheForHabit[key] = sessions;
      return sessions;
    } catch (e) {
      _setError('Failed to load sessions: $e');
      return [];
    }
  }

  Future<bool> deleteSession(int sessionId) async {
    _clearError();
    try {
      await _habitManager.deleteSession(sessionId);
      // Clear all session caches
      _sessionsByDayCache.clear();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete session: $e');
      return false;
    }
  }

  Future<bool> deleteAllSessionsForHabit(int habitId) async {
    _clearError();
    try {
      await _habitManager.deleteAllSessionsForHabit(habitId);
      // Clear running session and caches
      _runningSessions.remove(habitId);
      _pausedHabits.remove(habitId);
      _sessionsByDayCache.remove(habitId);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete sessions: $e');
      return false;
    }
  }

  Future<bool> toggleMultiSession(int habitId) async {
    _clearError();
    try {
      final habit = getHabitById(habitId);
      if (habit == null) return false;
      final updated = habit.copyWith(
        allowMultipleSessions: !habit.allowMultipleSessions,
      );
      await _habitManager.updateHabit(updated);
      await loadHabits();
      return true;
    } catch (e) {
      _setError('Failed to toggle multi-session: $e');
      return false;
    }
  }

  Future<bool> toggleTimerEnabled(int habitId,
      {bool deleteSessionsIfDisabled = true}) async {
    _clearError();
    try {
      final habit = getHabitById(habitId);
      if (habit == null) return false;
      final newTimerState = !habit.timerEnabled;

      // If turning OFF timer and deleteSessionsIfDisabled is true, delete all sessions
      if (!newTimerState && deleteSessionsIfDisabled) {
        await deleteAllSessionsForHabit(habitId);
      }

      final updated = habit.copyWith(
        timerEnabled: newTimerState,
      );
      await _habitManager.updateHabit(updated);
      await loadHabits();
      return true;
    } catch (e) {
      _setError('Failed to toggle timer: $e');
      return false;
    }
  }

  // Restore any running sessions from DB (endTs IS NULL)
  Future<void> _restoreRunningSessions() async {
    try {
      final running = await _habitManager.getAllRunningSessions();
      final now = DateTime.now().millisecondsSinceEpoch;
      _runningSessions
        ..clear()
        ..addEntries(running.map((s) => MapEntry(s.habitId, s)));
      _restoredSessionHabits
        ..clear()
        ..addAll(running.map((s) => s.habitId));
      _sessionAnomalyHabits.clear();
      for (final session in running) {
        final elapsed = now - session.startTs;
        if (elapsed < 0 || elapsed > _timerAnomalyThreshold.inMilliseconds) {
          _sessionAnomalyHabits.add(session.habitId);
        }
      }
      _pausedHabits.clear();
      notifyListeners();
    } catch (e) {
      _setError('Failed to restore running sessions: $e');
    }
  }

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
      await computeRecentSeries();
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
        await computeRecentSeries();
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

  // ==================== RECENT SERIES (SPARKLINE) ====================
  Future<void> computeRecentSeries({int days = 7}) async {
    if (_habits.isEmpty) {
      _recentStatusByHabit.clear();
      return;
    }
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    try {
      final records = await _habitManager.getRecordsInRange(start, now);
      final byHabitDate = <int, Map<String, HabitStatus>>{};
      for (final r in records) {
        final map = byHabitDate.putIfAbsent(r.habitId, () => {});
        map[r.date] = r.status;
      }

      final result = <int, List<HabitStatus>>{};
      for (final h in _habits) {
        if (h.id == null) continue;
        final list = <HabitStatus>[];
        for (int i = 0; i < days; i++) {
          final d = start.add(Duration(days: i));
          final key = _dateKey(d);
          final st = byHabitDate[h.id!]?[key];
          list.add(st ?? HabitStatus.missed);
        }
        result[h.id!] = list;
      }
      _recentStatusByHabit
        ..clear()
        ..addAll(result);
    } catch (e) {
      _setError('Failed to compute recent series: $e');
    }
  }
}
