import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hta/models/habit.dart';
import 'package:hta/models/habit_manager.dart';
import 'package:hta/models/habit_record.dart';
import 'package:hta/models/habit_session.dart';
import 'package:hta/providers/habit_provider.dart';
import 'package:hta/screens/habit_detail_screen.dart';

Future<void> _tapControl(WidgetTester tester, String label) async {
  final finder = find.text(label);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder, warnIfMissed: false);
  await tester.pump();
}

class _InMemoryHabitManager extends HabitManager {
  int _nextHabitId = 1;
  int _nextSessionId = 1;
  final Map<int, Habit> _habits = {};
  final Map<int, List<HabitSession>> _sessions = {};
  final Map<int, List<HabitRecord>> _records = {};

  @override
  Future<int> addHabit(String name) async {
    final id = _nextHabitId++;
    _habits[id] = Habit(
      id: id,
      name: name,
      createdAt: DateTime.now().toIso8601String(),
      timerEnabled: false,
      allowMultipleSessions: false,
    );
    return id;
  }

  @override
  Future<List<Habit>> loadHabits() async => _habits.values.toList();

  @override
  Future<void> updateHabit(Habit habit) async {
    if (habit.id != null) {
      _habits[habit.id!] = habit;
    }
  }

  @override
  Future<List<HabitRecord>> getRecordsForHabit(int habitId) async {
    return List.unmodifiable(_records[habitId] ?? const []);
  }

  @override
  Future<int> getCurrentStreak(int habitId) async => 0;

  @override
  Future<List<HabitRecord>> getRecordsInRange(
    DateTime startInclusive,
    DateTime endInclusive,
  ) async =>
      const [];

  @override
  Future<int> createSession({
    required int habitId,
    required int startTs,
    String? status,
    String? note,
  }) async {
    final session = HabitSession(
      id: _nextSessionId++,
      habitId: habitId,
      startTs: startTs,
      status: status,
      note: note,
      createdAt: startTs,
    );
    final list = _sessions.putIfAbsent(habitId, () => []);
    list.add(session);
    return session.id!;
  }

  @override
  Future<int> endSession({required int sessionId, required int endTs}) async {
    for (final entry in _sessions.entries) {
      final list = entry.value;
      for (var i = 0; i < list.length; i++) {
        final session = list[i];
        if (session.id == sessionId) {
          list[i] = session.copyWith(endTs: endTs);
          return 1;
        }
      }
    }
    return 0;
  }

  @override
  Future<List<HabitSession>> getSessionsForDay(
      int habitId, DateTime day) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final sessions = _sessions[habitId] ?? [];
    return sessions
        .where((session) {
          final start = DateTime.fromMillisecondsSinceEpoch(session.startTs);
          return !start.isBefore(startOfDay) && start.isBefore(endOfDay);
        })
        .map((s) => s)
        .toList();
  }

  @override
  Future<List<HabitSession>> getAllRunningSessions() async => const [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Habit Detail timer controls work correctly', (tester) async {
    final provider = HabitProvider(habitManager: _InMemoryHabitManager());

    expect(await provider.addHabit('Timer UI Habit'), isTrue);
    await provider.loadHabits();
    final habitId = provider.habits.first.id!;
    expect(await provider.toggleTimerEnabled(habitId), isTrue);
    final habit = provider.getHabitById(habitId)!;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: HabitDetailScreen(
            habit: habit,
            enablePeriodicTimer: false,
            loadRecordsOnInit: false,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Timer'), findsOneWidget);
    expect(find.byType(Switch), findsAtLeastNWidgets(2));

    await _tapControl(tester, 'Start Timer');

    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);

    await _tapControl(tester, 'Pause');
    expect(find.text('Resume'), findsOneWidget);

    await _tapControl(tester, 'Resume');
    expect(find.text('Pause'), findsOneWidget);

    await _tapControl(tester, 'Stop');
    expect(find.text('Start Timer'), findsOneWidget);
  });

  testWidgets('Habit Detail shows timer toggle switches', (tester) async {
    final provider = HabitProvider(habitManager: _InMemoryHabitManager());
    expect(await provider.addHabit('Switch Test Habit'), isTrue);
    await provider.loadHabits();
    final habit = provider.habits.first;

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: HabitDetailScreen(
            habit: habit,
            enablePeriodicTimer: false,
            loadRecordsOnInit: false,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(Switch), findsNWidgets(2));
    expect(find.text('Timer'), findsOneWidget);
    expect(find.text('Allow multiple sessions'), findsOneWidget);
  });
}
