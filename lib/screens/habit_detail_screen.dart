import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../models/habit_record.dart';
import '../models/habit_session.dart';
import '../providers/habit_provider.dart';
import '../widgets/day_detail_bottom_sheet.dart';
import '../widgets/statistics_widget.dart';
import '../services/preferences_service.dart';

class HabitDetailScreen extends StatefulWidget {
  final Habit habit;
  final bool enablePeriodicTimer;
  final bool loadRecordsOnInit;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    this.enablePeriodicTimer = true,
    this.loadRecordsOnInit = true,
  });

  @override
  State<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Map<String, HabitRecord> _records = {};
  int _currentStreak = 0;
  bool _isLoading = true;
  bool _isCalendarExpanded = false;

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

    if (widget.loadRecordsOnInit) {
      _loadRecords();
    } else {
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    final provider = context.read<HabitProvider>();
    final habitId = widget.habit.id!;

    try {
      final records = await provider.getRecordsForHabit(habitId);
      final streak = await provider.getCurrentStreak(habitId);

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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _showDayDetailSheet(DateTime day) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final existingRecord = _records[dateStr];
    final habitId = widget.habit.id!;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DayDetailBottomSheet(
        date: day,
        existingRecord: existingRecord,
        habitId: habitId,
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
        return const Color(0xFF50C878); // Emerald green
      case HabitStatus.missed:
        return const Color(0xFFB00020); // Error red
      case HabitStatus.skipped:
        return const Color(0xFFD4AF37); // Gold
    }
  }

  IconData _getIconForStatus(HabitStatus status) {
    switch (status) {
      case HabitStatus.complete:
        return Icons.check_rounded;
      case HabitStatus.missed:
        return Icons.close_rounded;
      case HabitStatus.skipped:
        return Icons.remove_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<HabitProvider>();
    final habit = provider.getHabitById(widget.habit.id!) ?? widget.habit;
    final habitId = habit.id ?? widget.habit.id!;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Hero(
          tag: 'habit_$habitId',
          child: Material(
            color: Colors.transparent,
            child: Text(
              habit.name,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
        actions: [
          Semantics(
            label: 'Session logs',
            button: true,
            child: IconButton(
              icon: Icon(Icons.history_rounded,
                  color: isDark ? Colors.white : null),
              onPressed: () {
                _showSessionLogsScreen(habitId, provider);
              },
              tooltip: 'Session Logs',
            ),
          ),
          Semantics(
            label: 'Timer settings',
            button: true,
            child: IconButton(
              icon: Icon(Icons.timer_outlined,
                  color: isDark ? Colors.white : null),
              onPressed: () {
                _showTimerSettingsSheet(habitId, habit, provider);
              },
              tooltip: 'Timer Settings',
            ),
          ),
          Semantics(
            label: 'View statistics and charts',
            button: true,
            child: IconButton(
              icon: Icon(Icons.show_chart_rounded,
                  color: isDark ? Colors.white : null),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => StatisticsWidget(
                    habitId: habitId,
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
                    // Compact inline streak
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '🔥',
                            style: TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$_currentStreak',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentStreak == 1 ? 'day streak' : 'days streak',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
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
                            const SizedBox(height: 12),
                            // Compact calendar with expand/collapse
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _isCalendarExpanded =
                                              !_isCalendarExpanded;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Calendar',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              _isCalendarExpanded
                                                  ? Icons.expand_less
                                                  : Icons.expand_more,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_isCalendarExpanded)
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: _buildCalendarContent(
                                            isDark, context),
                                      ),
                                  ],
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStopwatchSheet(habitId, provider),
        backgroundColor: provider.runningSessionFor(habitId) != null
            ? Colors.orange
            : Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        tooltip: provider.runningSessionFor(habitId) != null
            ? 'View Running Timer'
            : 'Start Stopwatch',
        icon: Icon(provider.runningSessionFor(habitId) != null
            ? Icons.timer
            : Icons.play_arrow_rounded),
        label: Text(provider.runningSessionFor(habitId) != null
            ? 'View Timer'
            : 'Start'),
      ),
    );
  }

  Widget _buildCalendarContent(bool isDark, BuildContext context) {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.now().add(const Duration(days: 1)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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
        titleTextStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: isDark
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: Theme.of(context).colorScheme.secondary,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.secondary,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          color: isDark
              ? const Color(0xFFD4AF37)
              : Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        weekendStyle: TextStyle(
          color: Theme.of(context).colorScheme.tertiary,
          fontWeight: FontWeight.w600,
        ),
      ),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        todayTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        selectedDecoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
        weekendTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.tertiary,
          fontWeight: FontWeight.w600,
        ),
        defaultTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontWeight: FontWeight.w500,
        ),
        outsideDaysVisible: false,
        cellMargin: const EdgeInsets.all(6),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          // Show a small dot marker for dates with activity
          final dateStr = DateFormat('yyyy-MM-dd').format(day);
          final hasRecord = _records.containsKey(dateStr);

          if (hasRecord) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Positioned(
              bottom: 1,
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFD4AF37)
                      : Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }
          return null;
        },
        defaultBuilder: (context, day, focusedDay) {
          final dateStr = DateFormat('yyyy-MM-dd').format(day);
          final record = _records[dateStr];

          if (record != null) {
            final statusColor = _getColorForStatus(record.status);
            return Container(
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor,
                    statusColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: statusColor.withOpacity(0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      _getIconForStatus(record.status),
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  if (record.note != null && record.note!.isNotEmpty)
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
          final dateStr = DateFormat('yyyy-MM-dd').format(day);
          final record = _records[dateStr];

          if (record != null) {
            return Container(
              margin: const EdgeInsets.all(3),
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
                    child: Icon(
                      _getIconForStatus(record.status),
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                  if (record.note != null && record.note!.isNotEmpty)
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
      ),
    );
  }

  void _showStopwatchSheet(int habitId, HabitProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _StopwatchScreen(
          habitId: habitId,
          provider: provider,
          onSessionSaved: () => _loadRecords(),
        ),
      ),
    );
  }

  void _showSessionLogsScreen(int habitId, HabitProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SessionLogsScreen(
          habitId: habitId,
          provider: provider,
        ),
      ),
    );
  }

  // Manual session entry - kept for potential future use
  // ignore: unused_element
  void _showManualAddSessionSheet(int habitId, HabitProvider provider) {
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    final durationController = TextEditingController();
    DateTime? selectedDate = _selectedDay;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Add Session Time',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Date picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary),
                      title: const Text('Date'),
                      subtitle:
                          Text(DateFormat('MMM d, yyyy').format(selectedDate!)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const Divider(),
                    // Start time picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.play_circle_outline,
                          color: Theme.of(context).colorScheme.primary),
                      title: const Text('Start Time'),
                      subtitle: Text(startTime != null
                          ? startTime!.format(context)
                          : 'Tap to select'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: startTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setModalState(() {
                            startTime = picked;
                            startTimeController.text = picked.format(context);
                            _updateDuration(setModalState, startTime, endTime,
                                durationController);
                          });
                        }
                      },
                    ),
                    const Divider(),
                    // End time picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.stop_circle_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      title: const Text('End Time'),
                      subtitle: Text(endTime != null
                          ? endTime!.format(context)
                          : 'Tap to select'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: endTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setModalState(() {
                            endTime = picked;
                            endTimeController.text = picked.format(context);
                            _updateDuration(setModalState, startTime, endTime,
                                durationController);
                          });
                        }
                      },
                    ),
                    const Divider(),
                    // Duration display
                    if (durationController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Icon(Icons.timer_outlined,
                                color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 12),
                            Text(
                              'Duration: ${durationController.text}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: startTime != null && endTime != null
                            ? () async {
                                await _saveManualSession(
                                  habitId,
                                  provider,
                                  selectedDate!,
                                  startTime!,
                                  endTime!,
                                );
                                if (context.mounted) Navigator.pop(context);
                              }
                            : null,
                        icon: const Icon(Icons.check),
                        label: const Text('Save Session'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _updateDuration(
    StateSetter setModalState,
    TimeOfDay? start,
    TimeOfDay? end,
    TextEditingController controller,
  ) {
    if (start == null || end == null) return;

    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    var durationMinutes = endMinutes - startMinutes;

    if (durationMinutes < 0) {
      durationMinutes += 24 * 60; // Handle overnight sessions
    }

    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;

    setModalState(() {
      if (hours > 0) {
        controller.text = '${hours}h ${minutes}m';
      } else {
        controller.text = '${minutes}m';
      }
    });
  }

  Future<void> _saveManualSession(
    int habitId,
    HabitProvider provider,
    DateTime date,
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) async {
    final startDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );

    var endDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    // Handle overnight sessions
    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(const Duration(days: 1));
    }

    try {
      // Create and immediately end the session
      final success = await provider.startTimer(habitId);
      if (success) {
        await provider.stopTimer(habitId, endTime: endDateTime);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session added successfully')),
        );
        await _loadRecords();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding session: $e')),
        );
      }
    }
  }

  Future<bool?> _showTimerDisableWarning(int habitId) async {
    bool dontShowAgain = false;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 12),
              Text('Turn Off Timer?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Turning off Timer will erase all existing session data for this habit.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Do not show this again for 7 days'),
                value: dontShowAgain,
                onChanged: (value) =>
                    setState(() => dontShowAgain = value ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );

    // Save preference if confirmed and checkbox was checked
    if (result == true && dontShowAgain) {
      await PreferencesService.disableTimerWarningFor7Days(habitId);
    }

    return result;
  }

  void _showTimerSettingsSheet(
      int habitId, Habit habit, HabitProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Timer Settings',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Timer Enable/Disable
                        Row(
                          children: [
                            Icon(
                              habit.timerEnabled
                                  ? Icons.timer
                                  : Icons.timer_off,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Timer',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            Switch(
                              value: habit.timerEnabled,
                              onChanged: (value) async {
                                if (habit.timerEnabled && !value) {
                                  // Turning OFF - check if warning should be shown
                                  final shouldShow = await PreferencesService
                                      .shouldShowTimerWarning(habitId);
                                  bool confirmed = true;

                                  if (shouldShow) {
                                    confirmed = await _showTimerDisableWarning(
                                            habitId) ??
                                        false;
                                  }

                                  if (confirmed) {
                                    await provider.toggleTimerEnabled(habitId,
                                        deleteSessionsIfDisabled: true);
                                    setModalState(() {});
                                    setState(() {});
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Timer disabled and all sessions deleted')),
                                      );
                                    }
                                  }
                                } else {
                                  // Turning ON - no warning needed
                                  await provider.toggleTimerEnabled(habitId,
                                      deleteSessionsIfDisabled: false);
                                  setModalState(() {});
                                  setState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                        if (habit.timerEnabled) ...[
                          const Divider(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Multiple sessions are automatically allowed when timer is enabled',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Timer settings are habit-specific and saved automatically',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Stopwatch Screen for tracking sessions
// This screen integrates with the provider's timer system for persistence
class _StopwatchScreen extends StatefulWidget {
  final int habitId;
  final HabitProvider provider;
  final VoidCallback onSessionSaved;

  const _StopwatchScreen({
    required this.habitId,
    required this.provider,
    required this.onSessionSaved,
  });

  @override
  State<_StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<_StopwatchScreen>
    with WidgetsBindingObserver {
  late Timer _updateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Update UI every 100ms for smooth timer display
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle - timer continues in background via database persistence
    if (state == AppLifecycleState.resumed) {
      // Refresh to show accurate time after resume
      if (mounted) setState(() {});
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Future<void> _startTimer() async {
    final success = await widget.provider.startTimer(widget.habitId);
    if (success && mounted) {
      setState(() {});
    }
  }

  Future<void> _pauseTimer() async {
    await widget.provider.pauseTimer(widget.habitId);
    if (mounted) setState(() {});
  }

  Future<void> _resumeTimer() async {
    await widget.provider.resumeTimer(widget.habitId);
    if (mounted) setState(() {});
  }

  Future<void> _stopAndSave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Timer?'),
        content: const Text('Do you want to stop and save this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Stop & Save'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.provider.stopTimer(widget.habitId);
        widget.onSessionSaved();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session saved successfully')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving session: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final runningSession = widget.provider.runningSessionFor(widget.habitId);
    final isRunning =
        runningSession != null && !widget.provider.isPaused(widget.habitId);
    final elapsed = widget.provider.elapsedDurationFor(widget.habitId);
    final startTime = runningSession != null
        ? DateTime.fromMillisecondsSinceEpoch(runningSession.startTs)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stopwatch'),
        actions: [
          if (runningSession != null)
            TextButton.icon(
              onPressed: _stopAndSave,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Text(
                _formatDuration(elapsed),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (runningSession == null)
                  FloatingActionButton.extended(
                    onPressed: _startTimer,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start'),
                    backgroundColor: Colors.green,
                  ),
                if (runningSession != null && isRunning)
                  FloatingActionButton.extended(
                    onPressed: _pauseTimer,
                    icon: const Icon(Icons.pause_rounded),
                    label: const Text('Pause'),
                    backgroundColor: Colors.orange,
                  ),
                if (runningSession != null && !isRunning) ...[
                  FloatingActionButton.extended(
                    onPressed: _resumeTimer,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Resume'),
                    backgroundColor: Colors.green,
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton.extended(
                    onPressed: _stopAndSave,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Stop & Save'),
                    backgroundColor: Colors.red,
                  ),
                ],
                if (runningSession != null && isRunning) ...[
                  const SizedBox(width: 16),
                  FloatingActionButton.extended(
                    onPressed: _stopAndSave,
                    icon: const Icon(Icons.stop_rounded),
                    label: const Text('Stop & Save'),
                    backgroundColor: Colors.red,
                  ),
                ],
              ],
            ),
            if (startTime != null) ...[
              const SizedBox(height: 40),
              Text(
                'Started: ${DateFormat('h:mm:ss a').format(startTime)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Session Logs Screen
class _SessionLogsScreen extends StatefulWidget {
  final int habitId;
  final HabitProvider provider;

  const _SessionLogsScreen({
    required this.habitId,
    required this.provider,
  });

  @override
  State<_SessionLogsScreen> createState() => _SessionLogsScreenState();
}

class _SessionLogsScreenState extends State<_SessionLogsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: today,
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _selectedDate =
                          _selectedDate.subtract(const Duration(days: 1));
                    });
                  },
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: today,
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: _isSameDay(_selectedDate, today)
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _isSameDay(_selectedDate, today)
                          ? 'Today'
                          : DateFormat('MMM d, yyyy').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isSameDay(_selectedDate, today)
                            ? Colors.white
                            : null,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _selectedDate.isBefore(today)
                      ? () {
                          setState(() {
                            _selectedDate =
                                _selectedDate.add(const Duration(days: 1));
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
          // Session list
          Expanded(
            child: FutureBuilder<List<HabitSession>>(
              future: widget.provider
                  .getSessionsForDay(widget.habitId, _selectedDate),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snapshot.data!;
                if (sessions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No sessions on this date',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).disabledColor,
                                  ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final start =
                        DateTime.fromMillisecondsSinceEpoch(session.startTs);
                    final end = session.endTs != null
                        ? DateTime.fromMillisecondsSinceEpoch(session.endTs!)
                        : null;
                    final duration = end != null
                        ? end.difference(start)
                        : DateTime.now().difference(start);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: end != null
                              ? const Color(0xFF50C878)
                              : Colors.orange,
                          child: Icon(
                            end != null ? Icons.check : Icons.timer,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          '${DateFormat('h:mm a').format(start)} - ${end != null ? DateFormat('h:mm a').format(end) : 'Running'}',
                        ),
                        subtitle: Text(
                          'Duration: ${_formatDuration(duration)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red,
                          onPressed: () => _deleteSession(session),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Future<void> _deleteSession(HabitSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && session.id != null) {
      final success = await widget.provider.deleteSession(session.id!);
      if (success && mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deleted')),
        );
      }
    }
  }
}

// Separate widget for timer display that rebuilds independently
class _TimerDisplay extends StatefulWidget {
  final int habitId;
  final HabitProvider provider;
  final bool paused;

  const _TimerDisplay({
    required this.habitId,
    required this.provider,
    required this.paused,
  });

  @override
  State<_TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<_TimerDisplay> {
  late Timer _timer;
  int _nowMs = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _nowMs = DateTime.now().millisecondsSinceEpoch);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final two = (int n) => n.toString().padLeft(2, '0');
    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    }
    return '${two(minutes)}:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = widget.provider.elapsedDurationFor(
      widget.habitId,
      referenceMillis: _nowMs,
    );

    return Row(
      children: [
        Icon(Icons.timer, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 8),
        Text(
          _formatDuration(elapsed),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const Spacer(),
        if (!widget.paused)
          TextButton.icon(
            onPressed: () => widget.provider.pauseTimer(widget.habitId),
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
          )
        else
          TextButton.icon(
            onPressed: () => widget.provider.resumeTimer(widget.habitId),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Resume'),
          ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: () => widget.provider.stopTimer(widget.habitId),
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
        ),
      ],
    );
  }
}

// Separate widget for sessions list that can update independently
class _SessionsList extends StatefulWidget {
  final int habitId;
  final DateTime selectedDay;
  final HabitProvider provider;

  const _SessionsList({
    required this.habitId,
    required this.selectedDay,
    required this.provider,
  });

  @override
  State<_SessionsList> createState() => _SessionsListState();
}

class _SessionsListState extends State<_SessionsList> {
  Timer? _timer;
  int _nowMs = DateTime.now().millisecondsSinceEpoch;
  late Future<List<HabitSession>> _sessionsFuture;
  bool _hasRunningSessions = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    _sessionsFuture = widget.provider.getSessionsForDay(
      widget.habitId,
      widget.selectedDay,
    );
    _sessionsFuture.then((sessions) {
      if (mounted) {
        final hasRunning = sessions.any((s) => s.endTs == null);
        if (hasRunning != _hasRunningSessions) {
          setState(() {
            _hasRunningSessions = hasRunning;
          });
          if (hasRunning && _timer == null) {
            _startTimer();
          } else if (!hasRunning && _timer != null) {
            _stopTimer();
          }
        }
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _nowMs = DateTime.now().millisecondsSinceEpoch);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void didUpdateWidget(_SessionsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDay != widget.selectedDay) {
      _loadSessions();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final two = (int n) => n.toString().padLeft(2, '0');
    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    }
    return '${two(minutes)}:${two(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history),
              const SizedBox(width: 8),
              Text(
                'Sessions on ${DateFormat('yMMMd').format(widget.selectedDay)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<HabitSession>>(
            key: ValueKey('sessions_${widget.selectedDay.toIso8601String()}'),
            future: _sessionsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SizedBox(
                  height: 60,
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              final sessions = snapshot.data ?? const [];
              if (sessions.isEmpty) {
                return SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(
                      'No sessions logged',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }
              return Card(
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    final start =
                        DateTime.fromMillisecondsSinceEpoch(session.startTs);
                    final end = session.endTs == null
                        ? null
                        : DateTime.fromMillisecondsSinceEpoch(session.endTs!);
                    final duration = end != null
                        ? end.difference(start)
                        : widget.provider.elapsedDurationFor(
                            session.habitId,
                            referenceMillis: _nowMs,
                          );
                    return ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: Text(
                        '${DateFormat.Hm().format(start)}'
                        '${end != null ? ' - ${DateFormat.Hm().format(end)}' : ' - running'}',
                      ),
                      subtitle: Text(
                        _formatDuration(duration),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
