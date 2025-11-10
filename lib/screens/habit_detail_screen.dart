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

class _HabitDetailScreenState extends State<HabitDetailScreen> with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<String, HabitRecord> _records = {};
  int _currentStreak = 0;
  bool _isLoading = true;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _loadRecords();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    final provider = context.read<HabitProvider>();

    try {
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
        _animationController.forward(); // Start animation
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading records: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Hero(
          tag: 'habit_${widget.habit.id}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              widget.habit.name,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        actions: [
          Semantics(
            label: 'View all notes for this habit',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.notes_rounded),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotesListScreen(
                      habitId: widget.habit.id!,
                    ),
                  ),
                );
                await _loadRecords();
              },
              tooltip: 'View All Notes',
            ),
          ),
          Semantics(
            label: 'View statistics and charts',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.show_chart_rounded),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => StatisticsWidget(
                    habitId: widget.habit.id!,
                  ),
                );
              },
              tooltip: 'View Statistics',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.secondary,
                            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '🔥',
                              style: TextStyle(fontSize: 56),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '$_currentStreak',
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1,
                              letterSpacing: -2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentStreak == 1 ? 'Day Streak' : 'Days Streak',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 0.5,
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
                            const SizedBox(height: 16),
                            Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: TableCalendar(
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
                                  headerStyle: HeaderStyle(
                                    titleCentered: true,
                                    formatButtonVisible: false,
                                    titleTextStyle: Theme.of(context).textTheme.titleLarge!,
                                  ),
                                  calendarStyle: CalendarStyle(
                                    todayDecoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                    todayTextStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    selectedDecoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary,
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
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getColorForStatus(record.status).withOpacity(0.4),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
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
                                              color: Theme.of(context).colorScheme.primary,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _getColorForStatus(record.status).withOpacity(0.4),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
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
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.primary,
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            day.day.toString(),
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Quick Stats Preview
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Quick Stats',
                                    style: Theme.of(context).textTheme.headlineMedium,
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
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildStatCard(
                                                  '🔥',
                                                  '${stats['currentStreak']}',
                                                  'Current Streak',
                                                  Theme.of(context).colorScheme.secondary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _buildStatCard(
                                                  '🏆',
                                                  '${stats['maxStreak']}',
                                                  'Best Streak',
                                                  Theme.of(context).colorScheme.tertiary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildStatCard(
                                                  '✅',
                                                  '${stats['completionRate'].toStringAsFixed(0)}%',
                                                  'Completion',
                                                  Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _buildStatCard(
                                                  '📊',
                                                  '${stats['totalRecords']}',
                                                  'Total Days',
                                                  Colors.purple,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          FilledButton.icon(
                                            onPressed: () {
                                              showModalBottomSheet(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor: Colors.transparent,
                                                builder: (context) =>
                                                    StatisticsWidget(
                                                  habitId: widget.habit.id!,
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.analytics_rounded),
                                            label: const Text('View Detailed Stats'),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: Theme.of(context).colorScheme.primary,
                                              minimumSize: const Size(double.infinity, 48),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Legend
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Legend',
                                        style: Theme.of(context).textTheme.titleLarge,
                                      ),
                                      const SizedBox(height: 12),
                                      _buildLegendItem(
                                          '✅', 'Completed', Theme.of(context).colorScheme.tertiary),
                                      _buildLegendItem(
                                          '❌', 'Missed', Colors.red.shade300),
                                      _buildLegendItem(
                                          '➖', 'Skipped', Colors.amber.shade300),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Colors.grey,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Has note',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: Semantics(
        label: 'Mark today\'s status',
        button: true,
        child: FloatingActionButton.extended(
          onPressed: () => _showDayDetailSheet(DateTime.now()),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Mark Today'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
