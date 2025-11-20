import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences
class PreferencesService {
  static const String _timerWarningPrefix = 'timer_warning_disabled_';

  /// Check if timer warning should be shown for a habit
  static Future<bool> shouldShowTimerWarning(int habitId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_timerWarningPrefix$habitId';
    final disabledUntil = prefs.getInt(key);

    if (disabledUntil == null) return true;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now >= disabledUntil) {
      // Expired, remove the preference
      await prefs.remove(key);
      return true;
    }

    return false;
  }

  /// Disable timer warning for 7 days for a specific habit
  static Future<void> disableTimerWarningFor7Days(int habitId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_timerWarningPrefix$habitId';
    final disabledUntil =
        DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;
    await prefs.setInt(key, disabledUntil);
  }

  /// Clear timer warning preference for a habit
  static Future<void> clearTimerWarningPreference(int habitId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_timerWarningPrefix$habitId';
    await prefs.remove(key);
  }
}
