import 'package:flutter/material.dart';
import '../models/habit_manager.dart';
import '../models/habit.dart';
import 'habit_detail_screen.dart';
import 'notes_list_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HabitManager _habitManager = HabitManager();
  List<Habit> _habits = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<int> _selectedHabitIds = {};

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading habits: $e')),
        );
      }
    }
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
      try {
        await _habitManager.addHabit(nameController.text.trim());
        await _loadHabits();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habit added successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding habit: $e')),
          );
        }
      }
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
      _selectedHabitIds.addAll(_habits.map((h) => h.id!));
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
      try {
        for (final habitId in _selectedHabitIds) {
          await _habitManager.deleteHabit(habitId);
        }
        _exitSelectionMode();
        await _loadHabits();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('$count habit${count > 1 ? 's' : ''} moved to trash')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting habits: $e')),
          );
        }
      }
    }
  }

  Future<void> _renameSelectedHabit() async {
    if (_selectedHabitIds.length != 1) return;

    final habitId = _selectedHabitIds.first;
    final habit = _habits.firstWhere((h) => h.id == habitId);
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
      try {
        final updatedHabit = habit.copyWith(name: nameController.text.trim());
        await _habitManager.updateHabit(updatedHabit);
        _exitSelectionMode();
        await _loadHabits();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habit renamed successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error renaming habit: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? _buildEmptyState()
              : _buildHabitList(),
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
            // Refresh after returning from notes screen
            await _loadHabits();
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
            // Refresh after returning from settings
            await _loadHabits();
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

  Widget _buildHabitList() {
    return ListView.builder(
      itemCount: _habits.length,
      itemBuilder: (context, index) {
        final habit = _habits[index];
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
              future: _habitManager.getCurrentStreak(habit.id!),
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
                // Refresh habits list after returning (in case streaks changed)
                _loadHabits();
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
