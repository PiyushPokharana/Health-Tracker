import 'package:flutter_test/flutter_test.dart';
import 'package:hta/models/habit_record.dart';
import 'package:hta/providers/habit_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String testId;
  _MockPathProviderPlatform(this.testId);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/tmp/test_provider_cache_$testId';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    final testId = DateTime.now().millisecondsSinceEpoch.toString();
    PathProviderPlatform.instance = _MockPathProviderPlatform(testId);
  });

  test('HabitProvider caches streaks and stats correctly', () async {
    final provider = HabitProvider();

    // Add habit
    final added = await provider.addHabit('Cache Test');
    expect(added, isTrue);

    await provider.loadHabits();
    expect(provider.habits.length, 1);
    final habitId = provider.habits.first.id!;

    // Add completion for today
    final saved = await provider.addOrUpdateRecord(
      habitId,
      DateTime.now(),
      HabitStatus.complete,
    );
    expect(saved, isTrue);

    // Current streak should be updated and cached
    final streakFromGetter = provider.currentStreakFor(habitId);
    expect(streakFromGetter, 1);

    final streak = await provider.getCurrentStreak(habitId);
    expect(streak, 1);

    // Stats should reflect one completed record
    final stats1 = await provider.getHabitStatistics(habitId);
    expect(stats1['totalRecords'], 1);
    expect(stats1['completedCount'], 1);

    // Call again to hit cache path
    final stats2 = await provider.getHabitStatistics(habitId);
    expect(stats2['totalRecords'], 1);
    expect(stats2['completedCount'], 1);
  });
}
