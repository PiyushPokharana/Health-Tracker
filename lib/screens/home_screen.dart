import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import 'habit_detail_screen.dart';
import 'notes_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Only keep local UI state (selection mode)
  bool _isSelectionMode = false;
  final Set<int> _selectedHabitIds = {};

  @override
  void initState() {
    super.initState();
    // Load habits using Provider - no setState needed!
    Future.microtask(
      () => context.read<HabitProvider>().loadHabits(),
    );
  }

  Future<void> _showAddHabitDialog() async {
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Habit'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Habit Name',
            hintText: 'e.g., Exercise, Read, Meditate',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      // Use Provider instead of HabitManager directly
      final provider = context.read<HabitProvider>();
      final success = await provider.addHabit(nameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Habit added successfully!'
                  : provider.errorMessage ?? 'Error adding habit',
            ),
          ),
        );
      }
      // No need to call _loadHabits() - Provider handles it automatically!
    }
  }

  void _toggleSelection(int habitId) {
    setState(() {
      if (_selectedHabitIds.contains(habitId)) {
        _selectedHabitIds.remove(habitId);
        if (_selectedHabitIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedHabitIds.add(habitId);
      }
    });
  }

  void _enterSelectionMode(int habitId) {
    setState(() {
      _isSelectionMode = true;
      _selectedHabitIds.clear();
      _selectedHabitIds.add(habitId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedHabitIds.clear();
    });
  }

  void _selectAll() {
    setState(() {
      _selectedHabitIds.clear();
      // Get habits from Provider instead of local state
      final habits = context.read<HabitProvider>().habits;
      _selectedHabitIds.addAll(habits.map((h) => h.id!));
    });
  }

  Future<void> _deleteSelectedHabits() async {
    final count = _selectedHabitIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Habits'),
        content: Text('Move $count habit${count > 1 ? 's' : ''} to trash?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Use Provider instead of HabitManager
      final provider = context.read<HabitProvider>();
      final success = await provider.deleteHabits(_selectedHabitIds.toList());

      _exitSelectionMode();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '$count habit${count > 1 ? 's' : ''} moved to trash'
                  : provider.errorMessage ?? 'Error deleting habits',
            ),
          ),
        );
      }
      // No need to call _loadHabits() - Provider handles it automatically!
    }
  }

  Future<void> _renameSelectedHabit() async {
    if (_selectedHabitIds.length != 1) return;

    final habitId = _selectedHabitIds.first;
    // Get habit from Provider instead of local state
    final habit = context.read<HabitProvider>().getHabitById(habitId);
    if (habit == null) return;

    final nameController = TextEditingController(text: habit.name);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Habit'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Habit Name',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.trim().isNotEmpty) {
      // Use Provider instead of HabitManager
      final provider = context.read<HabitProvider>();
      final updatedHabit = habit.copyWith(name: nameController.text.trim());
      final success = await provider.updateHabit(updatedHabit);

      _exitSelectionMode();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Habit renamed successfully!'
                  : provider.errorMessage ?? 'Error renaming habit',
            ),
          ),
        );
      }
      // No need to call _loadHabits() - Provider handles it automatically!
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to rebuild when habits change
    final provider = context.watch<HabitProvider>();
    final habits = provider.habits;
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : habits.isEmpty
              ? _buildEmptyState()
              : _buildHabitList(habits),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: _showAddHabitDialog,
              child: const Icon(Icons.add),
            ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      title: const Text('My Habits'),
      actions: [
        IconButton(
          icon: const Icon(Icons.notes),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotesListScreen(),
              ),
            );
            // Provider automatically refreshes - no manual reload needed!
          },
          tooltip: 'View All Notes',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
            // Reload habits in case any were restored from trash
            if (mounted) {
              context.read<HabitProvider>().loadHabits();
            }
          },
          tooltip: 'Settings',
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitSelectionMode,
      ),
      title: Text('${_selectedHabitIds.length} selected'),
      actions: [
        if (_selectedHabitIds.length == 1)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _renameSelectedHabit,
            tooltip: 'Rename',
          ),
        IconButton(
          icon: const Icon(Icons.select_all),
          onPressed: _selectAll,
          tooltip: 'Select All',
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _deleteSelectedHabits,
          tooltip: 'Delete',
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.track_changes,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No habits yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first habit',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitList(List<Habit> habits) {
    return ListView.builder(
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final isSelected = _selectedHabitIds.contains(habit.id);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: _isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleSelection(habit.id!),
                  )
                : const Icon(Icons.track_changes),
            title: Text(habit.name),
            subtitle: FutureBuilder<int>(
              // Use Provider for streak calculation
              future: context.read<HabitProvider>().getCurrentStreak(habit.id!),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final streak = snapshot.data!;
                  return Text(
                    streak > 0
                        ? '🔥 $streak day${streak > 1 ? 's' : ''} streak'
                        : 'No streak yet',
                    style: TextStyle(
                      color: streak > 0 ? Colors.orange : Colors.grey,
                    ),
                  );
                }
                return const Text('Loading...');
              },
            ),
            onTap: () async {
              if (_isSelectionMode) {
                _toggleSelection(habit.id!);
              } else {
                // Navigate to habit detail screen
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HabitDetailScreen(habit: habit),
                  ),
                );
                // Provider will automatically refresh if needed
              }
            },
            onLongPress: () {
              if (!_isSelectionMode) {
                _enterSelectionMode(habit.id!);
              }
            },
          ),
        );
      },
    );
  }
}
