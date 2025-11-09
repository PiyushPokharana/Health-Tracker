# Phase 8: State Management with Provider

## 📋 Overview

Phase 8 implements **Provider** state management to improve code organization, reduce boilerplate, and enable automatic UI updates when data changes.

## ✅ Completed Tasks

### 1. Dependency Added
```yaml
dependencies:
  provider: ^6.1.1  # State management
```

### 2. HabitProvider Created
**File:** `lib/providers/habit_provider.dart`

**Key Features:**
- Extends `ChangeNotifier` for reactive updates
- Wraps all `HabitManager` methods
- Manages loading states (`isLoading`)
- Handles error messages (`errorMessage`)
- Provides convenient getters (`habits`, `hasHabits`)

**Available Methods:**
```dart
// Habit Management
Future<void> loadHabits()
Future<bool> addHabit(String name)
Future<bool> updateHabit(Habit habit)
Future<bool> deleteHabits(List<int> habitIds)
Habit? getHabitById(int id)

// Trash Management
Future<List<Habit>> loadDeletedHabits()
Future<bool> restoreHabit(int habitId)
Future<bool> permanentlyDeleteHabit(int habitId)

// Record Management
Future<List<HabitRecord>> getRecordsForHabit(int habitId)
Future<HabitRecord?> getRecordForDate(int habitId, DateTime date)
Future<bool> addOrUpdateRecord(int habitId, DateTime date, HabitStatus status, {String? note})
Future<bool> deleteRecord(int recordId)

// Statistics
Future<int> getCurrentStreak(int habitId)
Future<int> getMaxStreak(int habitId)
Future<Map<String, dynamic>> getHabitStatistics(int habitId)

// Error Handling
void clearError()
```

### 3. App Initialization Updated
**File:** `lib/main.dart`

```dart
return ChangeNotifierProvider(
  create: (_) => HabitProvider(),
  child: MaterialApp(
    // ... app config
  ),
);
```

The entire app is now wrapped with `ChangeNotifierProvider`, making `HabitProvider` accessible to all widgets.

---

## 🔄 Migration Guide

### Before (setState approach):
```dart
class _HomeScreenState extends State<HomeScreen> {
  final HabitManager _habitManager = HabitManager();
  List<Habit> _habits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    try {
      final habits = await _habitManager.loadHabits();
      setState(() {
        _habits = habits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error
    }
  }

  Future<void> _addHabit(String name) async {
    await _habitManager.addHabit(name);
    await _loadHabits(); // Manual refresh
  }
}
```

### After (Provider approach):
```dart
class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load habits once on initialization
    Future.microtask(
      () => context.read<HabitProvider>().loadHabits()
    );
  }

  Future<void> _addHabit(String name) async {
    final provider = context.read<HabitProvider>();
    final success = await provider.addHabit(name);
    // UI automatically updates - no manual refresh needed!
  }

  @override
  Widget build(BuildContext context) {
    // Access provider data
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;
    final isLoading = provider.isLoading;

    if (isLoading) {
      return CircularProgressIndicator();
    }

    return ListView.builder(
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return ListTile(title: Text(habit.name));
      },
    );
  }
}
```

---

## 📚 Provider Usage Patterns

### 1. Read-Only Access (Build Method)
Use `context.watch<HabitProvider>()` to listen to changes:

```dart
@override
Widget build(BuildContext context) {
  final provider = context.watch<HabitProvider>();
  final habits = provider.habits;
  final isLoading = provider.isLoading;
  
  // Widget rebuilds automatically when provider changes
  return ListView.builder(...);
}
```

### 2. One-Time Access (No Rebuild)
Use `context.read<HabitProvider>()` for actions:

```dart
Future<void> _deleteHabit(int habitId) async {
  final provider = context.read<HabitProvider>();
  await provider.deleteHabits([habitId]);
  // No rebuild triggered here - provider handles it internally
}
```

### 3. Selective Listening (Consumer)
Use `Consumer<HabitProvider>` to rebuild only specific widgets:

```dart
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('Title'), // Never rebuilds
      Consumer<HabitProvider>(
        builder: (context, provider, child) {
          // Only this part rebuilds when provider changes
          return Text('Habits: ${provider.habits.length}');
        },
      ),
    ],
  );
}
```

### 4. Deep Widget Access (Selector)
Use `Selector<HabitProvider, T>` to rebuild only when specific data changes:

```dart
Selector<HabitProvider, int>(
  selector: (context, provider) => provider.habits.length,
  builder: (context, habitCount, child) {
    // Only rebuilds when habitCount changes, not all provider changes
    return Text('Total: $habitCount');
  },
)
```

---

## 🎯 Next Steps

### Screens to Refactor:

1. **HomeScreen** (Priority: HIGH)
   - Replace `_habitManager` with `context.watch<HabitProvider>()`
   - Remove `_habits` state variable
   - Remove `_isLoading` state variable
   - Remove `_loadHabits()` setState logic
   - Keep local UI state (selection mode, selected IDs)

2. **HabitDetailScreen** (Priority: MEDIUM)
   - Use provider for loading records
   - Use provider for saving records
   - Keep local UI state (calendar focus, selected day)

3. **TrashScreen** (Priority: LOW)
   - Use provider for loading deleted habits
   - Use provider for restore/delete actions

4. **NotesListScreen** (Priority: LOW)
   - Can stay as-is or use provider for loading notes

---

## ✨ Benefits Achieved

### Before Provider:
- ❌ Each screen creates its own HabitManager
- ❌ Data loaded multiple times unnecessarily
- ❌ Manual setState() calls everywhere
- ❌ Hard to share data between screens
- ❌ More boilerplate code

### After Provider:
- ✅ Single HabitManager instance (via provider)
- ✅ Data loaded once and shared
- ✅ Automatic UI updates via notifyListeners()
- ✅ Easy data sharing across widgets
- ✅ Cleaner, more maintainable code
- ✅ Better performance (selective rebuilds)
- ✅ Easier to test

---

## 🔧 Technical Details

### How Provider Works:

1. **ChangeNotifier**
   ```dart
   class HabitProvider extends ChangeNotifier {
     List<Habit> _habits = [];
     
     Future<void> loadHabits() async {
       _habits = await _habitManager.loadHabits();
       notifyListeners(); // Tells all listeners to rebuild
     }
   }
   ```

2. **Provider Widget**
   ```dart
   ChangeNotifierProvider(
     create: (_) => HabitProvider(), // Creates instance
     child: MyApp(),
   )
   ```

3. **Consumer Widgets**
   ```dart
   context.watch<HabitProvider>() // Rebuild when changed
   context.read<HabitProvider>()  // No rebuild, just access
   ```

### State Flow:
```
User Action → Provider Method → Update Internal State → notifyListeners() → Rebuild Listening Widgets
```

---

## 📖 Resources

- [Provider Package Documentation](https://pub.dev/packages/provider)
- [Flutter State Management Guide](https://docs.flutter.dev/development/data-and-backend/state-mgmt/simple)
- [Provider Best Practices](https://pub.dev/packages/provider#best-practices)

---

## 🐛 Common Pitfalls to Avoid

### 1. ❌ Don't call `context.watch()` in initState
```dart
// WRONG
@override
void initState() {
  super.initState();
  context.watch<HabitProvider>().loadHabits(); // Error!
}

// CORRECT
@override
void initState() {
  super.initState();
  Future.microtask(
    () => context.read<HabitProvider>().loadHabits()
  );
}
```

### 2. ❌ Don't use `context.watch()` in event handlers
```dart
// WRONG
onPressed: () {
  context.watch<HabitProvider>().addHabit(name); // Unnecessary rebuild
}

// CORRECT
onPressed: () {
  context.read<HabitProvider>().addHabit(name);
}
```

### 3. ❌ Don't forget to dispose controllers in StatefulWidgets
```dart
// Provider disposes itself, but your local state needs cleanup
@override
void dispose() {
  _textController.dispose();
  super.dispose();
}
```

---

## 📝 Status

**Phase 8.1:** ✅ Complete - Provider chosen and dependency added  
**Phase 8.2:** 🔄 In Progress - Provider infrastructure ready, screens need refactoring  

**Next:** Refactor HomeScreen to use Provider (eliminates ~50 lines of boilerplate!)

