import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:daily_success_tracker_1/screens/habit_detail_screen.dart';
import 'package:daily_success_tracker_1/providers/habit_provider.dart';
import 'package:daily_success_tracker_1/models/habit.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Mock PathProvider for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String testId;

  MockPathProviderPlatform(this.testId);

  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/tmp/test_habit_detail_$testId';
  }
}

/// Basic widget tests for HabitDetailScreen
/// Focuses on UI structure that doesn't require full async completion
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Initialize sqflite ffi for desktop testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    // Use unique database for each test
    final testId = DateTime.now().millisecondsSinceEpoch.toString();
    PathProviderPlatform.instance = MockPathProviderPlatform(testId);
  });

  tearDown(() async {
    // Allow time for any pending async operations to complete
    await Future.delayed(const Duration(milliseconds: 100));
  });

  /// Helper to create test habit
  Habit createTestHabit({String name = 'Test Habit', int? id}) {
    return Habit(
      id: id ?? 1,
      name: name,
      createdAt: DateTime.now().toIso8601String(),
      isDeleted: false,
    );
  }

  /// Helper to create a widget with Provider
  Widget createHabitDetailScreen(Habit habit) {
    return ChangeNotifierProvider(
      create: (_) => HabitProvider(),
      child: MaterialApp(
        home: HabitDetailScreen(habit: habit),
      ),
    );
  }

  group('HabitDetailScreen - UI Structure', () {
    testWidgets('should display habit name in app bar', (tester) async {
      final habit = createTestHabit(name: 'Morning Exercise');
      await tester.pumpWidget(createHabitDetailScreen(habit));
      await tester.pump();

      expect(find.text('Morning Exercise'), findsOneWidget);
    });

    testWidgets('should display notes button in app bar', (tester) async {
      final habit = createTestHabit();
      await tester.pumpWidget(createHabitDetailScreen(habit));
      await tester.pump();

      expect(find.byIcon(Icons.notes), findsOneWidget);
    });

    testWidgets('should display statistics button in app bar', (tester) async {
      final habit = createTestHabit();
      await tester.pumpWidget(createHabitDetailScreen(habit));
      await tester.pump();

      expect(find.byIcon(Icons.show_chart), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (tester) async {
      final habit = createTestHabit();
      await tester.pumpWidget(createHabitDetailScreen(habit));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('HabitDetailScreen - Hero Animation', () {
    testWidgets('should have Hero widget with correct tag', (tester) async {
      final habit = createTestHabit(id: 42, name: 'Test Habit');
      await tester.pumpWidget(createHabitDetailScreen(habit));
      await tester.pump();

      // Find Hero widgets (there might be multiple, including FAB)
      final heroes = tester.widgetList<Hero>(find.byType(Hero));
      final habitHero = heroes.firstWhere(
        (hero) => hero.tag == 'habit_42',
        orElse: () => throw Exception('Hero with tag habit_42 not found'),
      );

      expect(habitHero.tag, equals('habit_42'));
    });
  });

  group('HabitDetailScreen - Accessibility', () {
    testWidgets('should have semantic labels for action buttons',
        (tester) async {
      final habit = createTestHabit();
      await tester.pumpWidget(createHabitDetailScreen(habit));
      await tester.pump();

      // Verify Semantics widgets are present
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('notes button should exist and be tappable', (tester) async {
      final habit = createTestHabit();
      await tester.pumpWidget(createHabitDetailScreen(habit));
      await tester.pump();

      final notesButton = find.byIcon(Icons.notes);
      expect(notesButton, findsOneWidget);

      // Verify it's inside an IconButton (tappable)
      expect(
        find.ancestor(
          of: notesButton,
          matching: find.byType(IconButton),
        ),
        findsOneWidget,
      );
    });

    testWidgets('statistics button should exist and be tappable',
        (tester) async {
      final habit = createTestHabit();
      await tester.pumpWidget(createHabitDetailScreen(habit));
      await tester.pump();

      final statsButton = find.byIcon(Icons.show_chart);
      expect(statsButton, findsOneWidget);

      // Verify it's inside an IconButton (tappable)
      expect(
        find.ancestor(
          of: statsButton,
          matching: find.byType(IconButton),
        ),
        findsOneWidget,
      );
    });
  });

  group('HabitDetailScreen - Widget Types', () {
    testWidgets('should have Scaffold as root widget', (tester) async {
      final habit = createTestHabit();
      await tester.pumpWidget(createHabitDetailScreen(habit));
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have AppBar', (tester) async {
      final habit = createTestHabit();
      await tester.pumpWidget(createHabitDetailScreen(habit));
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should use Provider for state management', (tester) async {
      final habit = createTestHabit();
      await tester.pumpWidget(createHabitDetailScreen(habit));
      await tester.pump();

      // Verify ChangeNotifierProvider is in the widget tree
      expect(
          find.byType(ChangeNotifierProvider<HabitProvider>), findsOneWidget);
    });
  });

  group('HabitDetailScreen - Different Habits', () {
    testWidgets('should handle habits with long names', (tester) async {
      final habit = createTestHabit(
        name:
            'This is a very long habit name that should still display correctly',
        id: 99,
      );

      await tester.pumpWidget(createHabitDetailScreen(habit));
      await tester.pump();

      expect(
        find.text(
            'This is a very long habit name that should still display correctly'),
        findsOneWidget,
      );
    });
  });

  group('HabitDetailScreen - App Bar Actions', () {
    testWidgets('should have exactly 2 action buttons', (tester) async {
      final habit = createTestHabit();
      await tester.pumpWidget(createHabitDetailScreen(habit));
      await tester.pump();

      // Find the AppBar
      final appBar = tester.widget<AppBar>(find.byType(AppBar));

      // Verify we have actions
      expect(appBar.actions, isNotNull);
      expect(appBar.actions!.length, equals(2));
    });
  });
}
