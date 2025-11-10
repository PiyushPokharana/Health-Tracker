import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _isSelectionMode = false;
  final Set<int> _selectedHabitIds = {};
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    
    Future.microtask(
      () => context.read<HabitProvider>().loadHabits(),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _showAddHabitDialog() async {
    final nameController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Habit',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Habit Name',
            hintText: 'e.g., Exercise, Read, Meditate',
            prefixIcon: Icon(Icons.track_changes),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
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
      HapticFeedback.lightImpact(); // Light haptic for adding habit
      // Use Provider instead of HabitManager directly
      final provider = context.read<HabitProvider>();
      final success = await provider.addHabit(nameController.text.trim());

      if (mounted) {
        if (success) {
          HapticFeedback.mediumImpact(); // Success haptic
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Habit added successfully!'
                  : provider.errorMessage ?? 'Error adding habit',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      // No need to call _loadHabits() - Provider handles it automatically!
    }
  }

  void _toggleSelection(int habitId) {
    HapticFeedback.selectionClick(); // Light haptic for selection
    setState(() {
      if (_selectedHabitIds.contains(habitId)) {
        _selectedHabitIds.remove(habitId);
        if (_selectedHabitIds.isEmpty) {
          _isSelectionMode = false;
          _fabAnimationController.reverse(); // Animate FAB back in
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
      _fabAnimationController.forward(); // Animate FAB out
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedHabitIds.clear();
      _fabAnimationController.reverse(); // Animate FAB back in
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
      HapticFeedback.mediumImpact(); // Haptic for delete confirmation
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : habits.isEmpty
              ? _buildEmptyState()
              : _buildHabitList(habits),
      floatingActionButton: _isSelectionMode
          ? null
          : ScaleTransition(
              scale: _fabScaleAnimation,
              child: Semantics(
                label: 'Add new habit',
                button: true,
                child: FloatingActionButton.extended(
                  onPressed: _showAddHabitDialog,
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Habit'),
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      title: Text(
        'Upgrade',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Colors.white,
        ),
      ),
      actions: [
        Semantics(
          label: 'View all notes',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.notes_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotesListScreen(),
                ),
              );
            },
            tooltip: 'View All Notes',
          ),
        ),
        Semantics(
          label: 'Open settings',
          button: true,
          child: IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
              if (mounted) {
                context.read<HabitProvider>().loadHabits();
              }
            },
            tooltip: 'Settings',
          ),
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
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.track_changes_rounded,
              size: 80,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No habits yet',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start building better habits today',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _showAddHabitDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Your First Habit'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitList(List<Habit> habits) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final isSelected = _selectedHabitIds.contains(habit.id);

        return Semantics(
          label: 'Habit: ${habit.name}',
          button: true,
          child: Hero(
            tag: 'habit_${habit.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Card(
                elevation: isSelected ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.secondary
                        : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: InkWell(
                  onTap: () async {
                    if (_isSelectionMode) {
                      _toggleSelection(habit.id!);
                    } else {
                      HapticFeedback.lightImpact();
                      await Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                              HabitDetailScreen(habit: habit),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeOutCubic;
                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);
                            return SlideTransition(
                              position: offsetAnimation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      );
                    }
                  },
                  onLongPress: () {
                    if (!_isSelectionMode) {
                      HapticFeedback.mediumImpact();
                      _enterSelectionMode(habit.id!);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        if (_isSelectionMode)
                          Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelection(habit.id!),
                              shape: const CircleBorder(),
                            ),
                          )
                        else
                          Container(
                            width: 48,
                            height: 48,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.secondary,
                                  Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.track_changes_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              FutureBuilder<int>(
                                future: context
                                    .read<HabitProvider>()
                                    .getCurrentStreak(habit.id!),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    final streak = snapshot.data!;
                                    return Row(
                                      children: [
                                        Text(
                                          streak > 0 ? '🔥' : '⚪',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          streak > 0
                                              ? '$streak day${streak > 1 ? 's' : ''} streak'
                                              : 'No streak yet',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: streak > 0 
                                                ? Theme.of(context).colorScheme.secondary
                                                : Colors.grey[600],
                                            fontWeight: streak > 0 ? FontWeight.w500 : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return Text(
                                    'Loading...',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        if (!_isSelectionMode)
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.grey[400],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
