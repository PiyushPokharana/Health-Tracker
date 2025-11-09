import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/habit_record.dart';
import '../providers/habit_provider.dart';
import '../widgets/day_detail_bottom_sheet.dart';
import '../widgets/statistics_widget.dart';
import 'notes_list_screen.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen> {
  // Keep only local UI state
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // Data will come from Provider
  Map<String, HabitRecord> _records = {};
  int _currentStreak = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    final provider = context.read<HabitProvider>();

    try {
      // Use Provider instead of HabitManager
      final records = await provider.getRecordsForHabit(widget.habit.id!);
      final streak = await provider.getCurrentStreak(widget.habit.id!);

      final recordsMap = <String, HabitRecord>{};
      for (var record in records) {
        recordsMap[record.date] = record;
      }

      if (mounted) {
        setState(() {
          _records = recordsMap;
          _currentStreak = streak;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading records: $e')),
        );
      }
    }
  }

  Future<void> _showDayDetailSheet(DateTime day) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final existingRecord = _records[dateStr];

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DayDetailBottomSheet(
        date: day,
        existingRecord: existingRecord,
        habitId: widget.habit.id!,
      ),
    );

    if (result == true) {
      // Refresh data after save/delete - Provider handles the update
      await _loadRecords();
    }
  }

  Color _getColorForStatus(HabitStatus status) {
    switch (status) {
      case HabitStatus.complete:
        return Colors.green;
      case HabitStatus.missed:
        return Colors.red.shade300;
      case HabitStatus.skipped:
        return Colors.amber.shade300;
    }
  }

  String _getIconForStatus(HabitStatus status) {
    switch (status) {
      case HabitStatus.complete:
        return '✅';
      case HabitStatus.missed:
        return '❌';
      case HabitStatus.skipped:
        return '➖';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habit.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.notes),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotesListScreen(
                    habitId: widget.habit.id!,
                  ),
                ),
              );
              // Refresh after returning from notes screen
              await _loadRecords();
            },
            tooltip: 'View All Notes',
          ),
          IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => StatisticsWidget(
                  habitId: widget.habit.id!,
                ),
              );
            },
            tooltip: 'View Statistics',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Streak Display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade400,
                        Colors.deepOrange.shade400,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '🔥',
                        style: TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_currentStreak Day${_currentStreak != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Current Streak',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Calendar
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.now().add(const Duration(days: 1)),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            if (!selectedDay.isAfter(DateTime.now())) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                              _showDayDetailSheet(selectedDay);
                            }
                          },
                          onPageChanged: (focusedDay) {
                            setState(() {
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: Colors.blue.shade300,
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                            ),
                            outsideDaysVisible: false,
                          ),
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) {
                              final dateStr =
                                  DateFormat('yyyy-MM-dd').format(day);
                              final record = _records[dateStr];

                              if (record != null) {
                                return Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _getColorForStatus(record.status),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Text(
                                          _getIconForStatus(record.status),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      if (record.note != null &&
                                          record.note!.isNotEmpty)
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }
                              return null;
                            },
                            todayBuilder: (context, day, focusedDay) {
                              final dateStr =
                                  DateFormat('yyyy-MM-dd').format(day);
                              final record = _records[dateStr];

                              if (record != null) {
                                return Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _getColorForStatus(record.status),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue.shade700,
                                      width: 2,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Text(
                                          _getIconForStatus(record.status),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      if (record.note != null &&
                                          record.note!.isNotEmpty)
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }
                              return Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade300,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    day.day.toString(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(),
                        // Quick Stats Preview
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quick Stats',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              FutureBuilder<Map<String, dynamic>>(
                                future: context
                                    .read<HabitProvider>()
                                    .getHabitStatistics(widget.habit.id!),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  final stats = snapshot.data!;
                                  return Column(
                                    children: [
                                      _buildStatRow(
                                        '🔥 Current Streak',
                                        '${stats['currentStreak']} days',
                                      ),
                                      _buildStatRow(
                                        '🏆 Best Streak',
                                        '${stats['maxStreak']} days',
                                      ),
                                      _buildStatRow(
                                        '✅ Completion Rate',
                                        '${stats['completionRate'].toStringAsFixed(1)}%',
                                      ),
                                      _buildStatRow(
                                        '📊 Total Days',
                                        '${stats['totalRecords']}',
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            builder: (context) =>
                                                StatisticsWidget(
                                              habitId: widget.habit.id!,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.analytics),
                                        label:
                                            const Text('View Detailed Stats'),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Legend
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Legend',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildLegendItem(
                                      '✅', 'Completed', Colors.green),
                                  _buildLegendItem(
                                      '❌', 'Missed', Colors.red.shade300),
                                  _buildLegendItem(
                                      '➖', 'Skipped', Colors.amber.shade300),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Has note'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDayDetailSheet(DateTime.now()),
        icon: const Icon(Icons.add),
        label: const Text('Mark Today'),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
