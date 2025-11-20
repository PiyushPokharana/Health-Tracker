import 'package:flutter_test/flutter_test.dart';
import 'package:hta/providers/habit_provider.dart';
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

  test('toggle timer and resume/pause sequence', () async {
    final basePath =
        '/tmp/test_provider_timer_${DateTime.now().millisecondsSinceEpoch}';
    PathProviderPlatform.instance = _MockPathProviderPlatform(basePath);

    final provider = HabitProvider();

    expect(await provider.addHabit('Toggle Habit'), isTrue);
    await provider.loadHabits();
    final habitId = provider.habits.first.id!;

    // Initially disabled
    expect(provider.getHabitById(habitId)!.timerEnabled, isFalse);

    // Toggle on
    expect(await provider.toggleTimerEnabled(habitId), isTrue);
    expect(provider.getHabitById(habitId)!.timerEnabled, isTrue);

    // Start -> pause -> resume -> stop
    expect(await provider.startTimer(habitId), isTrue);
    expect(provider.runningSessionFor(habitId), isNotNull);

    expect(await provider.pauseTimer(habitId), isTrue);
    expect(provider.isPaused(habitId), isTrue);

    expect(await provider.resumeTimer(habitId), isTrue);
    expect(provider.isPaused(habitId), isFalse);

    expect(await provider.stopTimer(habitId), isTrue);
    expect(provider.runningSessionFor(habitId), isNull);

    // Toggle off
    expect(await provider.toggleTimerEnabled(habitId), isTrue);
    expect(provider.getHabitById(habitId)!.timerEnabled, isFalse);
  });
}
