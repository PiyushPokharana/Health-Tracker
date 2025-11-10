import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/habit_record.dart';
import '../models/habit_manager.dart';
import 'habit_detail_screen.dart';

class NotesListScreen extends StatefulWidget {
  final int? habitId; // Optional: if provided, show notes only for this habit

  const NotesListScreen({
    super.key,
    this.habitId,
  });

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final HabitManager _habitManager = HabitManager();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<HabitStatus> _selectedStatuses = {
    HabitStatus.complete,
    HabitStatus.missed,
    HabitStatus.skipped,
  };
  Set<int> _selectedHabitIds = {};
  DateTimeRange? _dateRange;
  bool _showFilters = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final habits = await _habitManager.loadHabits();
      setState(() {
        // Initialize with all habits selected
        if (widget.habitId != null) {
          _selectedHabitIds.add(widget.habitId!);
        } else {
          _selectedHabitIds = habits.map((h) => h.id!).toSet();
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<_NoteItem>> _getFilteredNotes() async {
    List<_NoteItem> allNotes = [];

    // Reload habits to ensure we have latest data
    final habits = await _habitManager.loadHabits();

    // Collect all notes from all habits
    for (var habit in habits) {
      if (!_selectedHabitIds.contains(habit.id)) continue;

      final records = await _habitManager.getRecordsForHabit(habit.id!);
      for (var record in records) {
        if (record.note == null || record.note!.isEmpty) continue;
        if (!_selectedStatuses.contains(record.status)) continue;

        // Parse date string to DateTime for comparison
        final recordDate = DateTime.parse(record.date);

        // Date range filter
        if (_dateRange != null) {
          if (recordDate.isBefore(_dateRange!.start) ||
              recordDate.isAfter(_dateRange!.end)) {
            continue;
          }
        }

        // Search filter
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          final noteContains = record.note!.toLowerCase().contains(searchLower);
          final habitContains = habit.name.toLowerCase().contains(searchLower);
          if (!noteContains && !habitContains) continue;
        }

        allNotes.add(_NoteItem(
          habit: habit,
          record: record,
        ));
      }
    }

    // Sort by date, most recent first
    allNotes.sort((a, b) => b.record.date.compareTo(a.record.date));
    return allNotes;
  }

  @override
  Widget build(BuildContext context) {
    final isFiltered = widget.habitId != null;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isFiltered ? 'Habit Notes' : 'All Notes'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isFiltered ? 'Habit Notes' : 'All Notes'),
        actions: [
          IconButton(
            icon: Icon(
                _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filter Panel
          if (_showFilters) _buildFilterPanel(),

          // Notes List
          Expanded(
            child: FutureBuilder<List<_NoteItem>>(
              future: _getFilteredNotes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final filteredNotes = snapshot.data ?? [];

                if (filteredNotes.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredNotes.length,
                  itemBuilder: (context, index) {
                    return _buildNoteCard(filteredNotes[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Filter
          Text(
            'Status',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 16),
                    SizedBox(width: 4),
                    Text('Complete'),
                  ],
                ),
                selected: _selectedStatuses.contains(HabitStatus.complete),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedStatuses.add(HabitStatus.complete);
                    } else {
                      _selectedStatuses.remove(HabitStatus.complete);
                    }
                  });
                },
              ),
              FilterChip(
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel_rounded, size: 16),
                    SizedBox(width: 4),
                    Text('Missed'),
                  ],
                ),
                selected: _selectedStatuses.contains(HabitStatus.missed),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedStatuses.add(HabitStatus.missed);
                    } else {
                      _selectedStatuses.remove(HabitStatus.missed);
                    }
                  });
                },
              ),
              FilterChip(
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.do_not_disturb_on_rounded, size: 16),
                    SizedBox(width: 4),
                    Text('Skipped'),
                  ],
                ),
                selected: _selectedStatuses.contains(HabitStatus.skipped),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedStatuses.add(HabitStatus.skipped);
                    } else {
                      _selectedStatuses.remove(HabitStatus.skipped);
                    }
                  });
                },
              ),
            ],
          ),

          // Habit Filter (only show if viewing all habits)
          if (widget.habitId == null) ...[
            const SizedBox(height: 16),
            Text(
              'Habits',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Habit>>(
              future: _habitManager.loadHabits(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: snapshot.data!.map((habit) {
                    return FilterChip(
                      label: Text(habit.name),
                      selected: _selectedHabitIds.contains(habit.id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedHabitIds.add(habit.id!);
                          } else {
                            _selectedHabitIds.remove(habit.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ],

          // Date Range Filter
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Date Range',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(width: 8),
              if (_dateRange != null)
                TextButton.icon(
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                  onPressed: () {
                    setState(() {
                      _dateRange = null;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _dateRange == null
                  ? 'Select Date Range'
                  : '${DateFormat.MMMd().format(_dateRange!.start)} - ${DateFormat.MMMd().format(_dateRange!.end)}',
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (picked != null) {
                setState(() {
                  _dateRange = picked;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(_NoteItem noteItem) {
    final habit = noteItem.habit;
    final record = noteItem.record;
    final recordDate = DateTime.parse(record.date);
    final isToday = DateUtils.isSameDay(recordDate, DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // Navigate to habit detail screen
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HabitDetailScreen(
                habit: habit,
              ),
            ),
          );
          // Refresh the list
          setState(() {});
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Habit name, date, status
              Row(
                children: [
                  // Status Icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getStatusColor(record.status),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _getStatusIcon(record.status),
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          isToday
                              ? 'Today'
                              : DateFormat('EEEE, MMMM d, y')
                                  .format(recordDate),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Note content
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.note!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _dateRange != null
                ? 'No notes match your filters'
                : 'No notes yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _dateRange != null
                ? 'Try adjusting your search or filters'
                : 'Add notes to your habit records to see them here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(HabitStatus status) {
    switch (status) {
      case HabitStatus.complete:
        return const Color(0xFF50C878).withOpacity(0.2); // Emerald green light
      case HabitStatus.missed:
        return const Color(0xFFB00020).withOpacity(0.2); // Error red light
      case HabitStatus.skipped:
        return const Color(0xFFD4AF37).withOpacity(0.2); // Gold light
    }
  }

  IconData _getStatusIcon(HabitStatus status) {
    switch (status) {
      case HabitStatus.complete:
        return Icons.check_circle_rounded;
      case HabitStatus.missed:
        return Icons.cancel_rounded;
      case HabitStatus.skipped:
        return Icons.do_not_disturb_on_rounded;
    }
  }
}

class _NoteItem {
  final Habit habit;
  final HabitRecord record;

  _NoteItem({
    required this.habit,
    required this.record,
  });
}
