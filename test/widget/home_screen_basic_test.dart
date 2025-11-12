import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:hta/screens/home_screen.dart';
import 'package:hta/providers/habit_provider.dart';
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
    return '/tmp/test_home_basic_$testId';
  }
}

/// Basic widget tests for HomeScreen
/// Focuses on UI structure and elements that don't require full async completion
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

  /// Helper to create a widget with Provider
  Widget createHomeScreen() {
    return ChangeNotifierProvider(
      create: (_) => HabitProvider(),
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  group('HomeScreen - UI Structure', () {
    testWidgets('should display app bar with correct title', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.text('My Habits'), findsOneWidget);
    });

    testWidgets('should display FloatingActionButton with add icon',
        (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should display notes and settings buttons in app bar',
        (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.byIcon(Icons.notes), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('should show loading indicator initially', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      // The app starts by loading habits, so we should see a progress indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('HomeScreen - Dialog Interactions', () {
    testWidgets('should open add habit dialog when FAB is tapped',
        (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      // Wait a bit for initial state
      await tester.pump(const Duration(milliseconds: 100));

      // Tap FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(); // Start animation
      await tester
          .pump(const Duration(milliseconds: 500)); // Complete animation

      // Verify dialog appears
      expect(find.text('Add New Habit'), findsOneWidget);
      expect(find.text('Habit Name'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('should close dialog when Cancel is tapped', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Open dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Add New Habit'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pump(); // Start animation
      await tester
          .pump(const Duration(milliseconds: 500)); // Complete animation

      // Dialog should be closed
      expect(find.text('Add New Habit'), findsNothing);
    });

    testWidgets('should accept text input in habit name field', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Open dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Enter text in the TextField
      await tester.enterText(find.byType(TextField), 'Morning Meditation');
      await tester.pump();

      // Verify text was entered
      expect(find.text('Morning Meditation'), findsOneWidget);
    });
  });

  group('HomeScreen - Accessibility', () {
    testWidgets('should have Semantics widgets for accessibility',
        (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      // Verify that Semantics widgets are present
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('FAB should be accessible', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      // Find the FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      // FAB should be tappable
      await tester.tap(fab);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Dialog should open, confirming FAB works
      expect(find.text('Add New Habit'), findsOneWidget);
    });
  });

  group('HomeScreen - Widget Types', () {
    testWidgets('should have Scaffold as root widget', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('should have AppBar', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('should use Provider for state management', (tester) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pump();

      // Verify ChangeNotifierProvider is in the widget tree
      expect(
          find.byType(ChangeNotifierProvider<HabitProvider>), findsOneWidget);
    });
  });
}
