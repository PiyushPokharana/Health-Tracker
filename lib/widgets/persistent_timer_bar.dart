import 'dart:async';
import 'package:flutter/material.dart';
import '../models/habit_session.dart';
import '../providers/habit_provider.dart';

/// Persistent timer bar shown at bottom of screen when any timer is running
class PersistentTimerBar extends StatefulWidget {
  final HabitProvider provider;
  final VoidCallback? onTap;

  const PersistentTimerBar({
    super.key,
    required this.provider,
    this.onTap,
  });

  @override
  State<PersistentTimerBar> createState() => _PersistentTimerBarState();
}

class _PersistentTimerBarState extends State<PersistentTimerBar> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    // Update every second to show accurate elapsed time
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get all running sessions
    final runningSessions = <int, HabitSession>{};
    for (var habit in widget.provider.habits) {
      if (habit.id != null) {
        final session = widget.provider.runningSessionFor(habit.id!);
        if (session != null) {
          runningSessions[habit.id!] = session;
        }
      }
    }

    if (runningSessions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get the first running session (or could show multiple)
    final entry = runningSessions.entries.first;
    final habitId = entry.key;
    final habit = widget.provider.getHabitById(habitId);
    final isPaused = widget.provider.isPaused(habitId);
    final elapsed = widget.provider.elapsedDurationFor(habitId);

    return Material(
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Timer icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPaused
                          ? Colors.orange.withOpacity(0.3)
                          : const Color(0xFF50C878).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPaused ? Icons.pause : Icons.timer,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Habit name and timer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          habit?.name ?? 'Timer Running',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDuration(elapsed),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Control buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isPaused)
                        IconButton(
                          icon: const Icon(Icons.pause, color: Colors.white),
                          onPressed: () => widget.provider.pauseTimer(habitId),
                          tooltip: 'Pause',
                        )
                      else
                        IconButton(
                          icon:
                              const Icon(Icons.play_arrow, color: Colors.white),
                          onPressed: () => widget.provider.resumeTimer(habitId),
                          tooltip: 'Resume',
                        ),
                      IconButton(
                        icon: const Icon(Icons.stop, color: Colors.white),
                        onPressed: () => _confirmStop(habitId),
                        tooltip: 'Stop',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final twoDigits = (int n) => n.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  Future<void> _confirmStop(int habitId) async {
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
      await widget.provider.stopTimer(habitId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session saved successfully')),
        );
      }
    }
  }
}
