import 'package:flutter_test/flutter_test.dart';
import 'package:hta/providers/habit_provider.dart';
import 'package:hta/models/habit_session.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String path;
  _MockPathProviderPlatform(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('start/stop timer and restore running session', () async {
    // Use a fixed path so a new provider instance sees the same DB
    final basePath =
        '/tmp/test_provider_sessions_${DateTime.now().millisecondsSinceEpoch}';
    PathProviderPlatform.instance = _MockPathProviderPlatform(basePath);

    final provider = HabitProvider();

    // Create a habit
    expect(await provider.addHabit('Timer Habit'), isTrue);
    await provider.loadHabits();
    final habitId = provider.habits.first.id!;

    // Start timer
    expect(await provider.startTimer(habitId), isTrue);
    final running1 = provider.runningSessionFor(habitId);
    expect(running1, isA<HabitSession>());
    expect(running1!.endTs, isNull);

    // Simulate app restart: new provider with same storage
    PathProviderPlatform.instance = _MockPathProviderPlatform(basePath);
    final provider2 = HabitProvider();
    await provider2.init();

    final restored = provider2.runningSessionFor(habitId);
    expect(restored, isNotNull);
    expect(restored!.endTs, isNull);

    // Stop timer from new provider
    expect(await provider2.stopTimer(habitId), isTrue);
    final runningAfterStop = provider2.runningSessionFor(habitId);
    expect(runningAfterStop, isNull);

    // Verify a session exists for today
    final sessionsToday =
        await provider2.getSessionsForDay(habitId, DateTime.now());
    expect(sessionsToday.length, 1);
    expect(sessionsToday.first.endTs, isNotNull);
  });
}
