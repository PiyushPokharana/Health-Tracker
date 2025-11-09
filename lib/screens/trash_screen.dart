import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  @override
  void initState() {
    super.initState();
    // Load deleted habits when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HabitProvider>().loadDeletedHabits();
    });
  }

  Future<void> _restoreHabit(Habit habit) async {
    final provider = context.read<HabitProvider>();
    final success = await provider.restoreHabit(habit.id!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '${habit.name} restored successfully!'
                : provider.errorMessage ?? 'Error restoring habit',
          ),
          action: success
              ? SnackBarAction(
                  label: 'OK',
                  onPressed: () {},
                )
              : null,
        ),
      );
    }
  }

  Future<void> _permanentlyDeleteHabit(Habit habit) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete?'),
        content: Text(
          'Are you sure you want to permanently delete "${habit.name}"?\n\n'
          'This will delete all records for this habit. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<HabitProvider>();
      final success = await provider.permanentlyDeleteHabit(habit.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '${habit.name} permanently deleted'
                  : provider.errorMessage ?? 'Error deleting habit',
            ),
          ),
        );
      }
    }
  }

  Future<void> _emptyTrash() async {
    final provider = context.read<HabitProvider>();
    final deletedHabits = provider.deletedHabits;

    if (deletedHabits.isEmpty) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: Text(
          'Are you sure you want to permanently delete all ${deletedHabits.length} habit(s)?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<HabitProvider>();

      // Get current deleted habits before deletion
      final habitsToDelete = provider.deletedHabits;

      // Delete all habits
      for (var habit in habitsToDelete) {
        await provider.permanentlyDeleteHabit(habit.id!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trash emptied successfully')),
        );
      }
    }
  }

  String _getDaysInTrash(String? deletedAt) {
    if (deletedAt == null) return 'Unknown';
    try {
      final deletedDate = DateTime.parse(deletedAt);
      final daysAgo = DateTime.now().difference(deletedDate).inDays;
      if (daysAgo == 0) return 'Today';
      if (daysAgo == 1) return '1 day ago';
      final daysRemaining = 30 - daysAgo;
      if (daysRemaining > 0) {
        return '$daysAgo days ago (${daysRemaining} days until permanent deletion)';
      } else {
        return '$daysAgo days ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch Provider for changes
    final provider = context.watch<HabitProvider>();
    final deletedHabits = provider.deletedHabits;
    final isLoading = provider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          if (deletedHabits.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _emptyTrash,
              tooltip: 'Empty Trash',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : deletedHabits.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Info Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Habits are automatically deleted after 30 days in trash',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Habit List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: deletedHabits.length,
                        itemBuilder: (context, index) {
                          return _buildDeletedHabitCard(deletedHabits[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 80,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Trash is Empty',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Deleted habits will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedHabitCard(Habit habit) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Habit Name
            Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    habit.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Deletion Info
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getDaysInTrash(habit.deletedAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _permanentlyDeleteHabit(habit),
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Delete Forever'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _restoreHabit(habit),
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
