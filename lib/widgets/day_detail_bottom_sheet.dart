import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/habit_record.dart';
import '../providers/habit_provider.dart';

class DayDetailBottomSheet extends StatefulWidget {
  final DateTime date;
  final HabitRecord? existingRecord;
  final int habitId;

  const DayDetailBottomSheet({
    super.key,
    required this.date,
    this.existingRecord,
    required this.habitId,
  });

  @override
  State<DayDetailBottomSheet> createState() => _DayDetailBottomSheetState();
}

class _DayDetailBottomSheetState extends State<DayDetailBottomSheet> {
  HabitStatus? _selectedStatus;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      _selectedStatus = widget.existingRecord!.status;
      _noteController.text = widget.existingRecord!.note ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (_selectedStatus == null) {
      HapticFeedback.lightImpact(); // Light vibration for error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a status')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Use Provider instead of HabitManager
      final provider = context.read<HabitProvider>();
      final success = await provider.addOrUpdateRecord(
        widget.habitId,
        widget.date,
        _selectedStatus!,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (mounted) {
        if (success) {
          HapticFeedback.mediumImpact(); // Success vibration
        }
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Record saved!'
                  : provider.errorMessage ?? 'Error saving record',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving record: $e')),
        );
      }
    }
  }

  Future<void> _deleteRecord() async {
    if (widget.existingRecord == null) {
      Navigator.pop(context, false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: const Text('Are you sure you want to delete this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedback.mediumImpact(); // Confirm delete action
      setState(() => _isSaving = true);
      try {
        // Use Provider instead of HabitManager
        final provider = context.read<HabitProvider>();
        final success = await provider.deleteRecord(widget.existingRecord!.id!);

        if (mounted) {
          Navigator.pop(context, true); // Return true to refresh
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? 'Record deleted'
                    : provider.errorMessage ?? 'Error deleting record',
              ),
            ),
          );
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting record: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = DateFormat('yyyy-MM-dd').format(widget.date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final isFuture = widget.date.isAfter(DateTime.now());

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, MMMM d').format(widget.date),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (isToday)
                        Text(
                          'Today',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (isFuture)
                        Text(
                          'Future date',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? const Color(0xFFB0B0B0)
                                    : Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                  if (widget.existingRecord != null)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: _isSaving ? null : _deleteRecord,
                      tooltip: 'Delete record',
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Status Selection
              Text(
                'Status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatusButton(
                      status: HabitStatus.complete,
                      icon: Icons.check_rounded,
                      label: 'Complete',
                      color: const Color(0xFF50C878), // Emerald green
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusButton(
                      status: HabitStatus.missed,
                      icon: Icons.close_rounded,
                      label: 'Missed',
                      color: const Color(0xFFEF5350), // Brighter red
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatusButton(
                      status: HabitStatus.skipped,
                      icon: Icons.remove_rounded,
                      label: 'Skipped',
                      color: const Color(0xFFD4AF37), // Gold
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Note Section
              Text(
                'Note (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Note text field',
                hint: 'Add a note about this day',
                textField: true,
                child: TextField(
                  controller: _noteController,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: 'Add a note about this day...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Cancel without saving',
                      button: true,
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Semantics(
                      label: 'Save habit status and note',
                      button: true,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveRecord,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton({
    required HabitStatus status,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedStatus == status;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? (isSelected ? color : const Color(0xFFD4AF37).withOpacity(0.5))
        : (isSelected ? color : Colors.grey.shade300);

    return Semantics(
      label: 'Mark as $label',
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick(); // Light click feedback
          setState(() {
            _selectedStatus = status;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.2)
                : (isDark ? const Color(0xFF0A1628) : Colors.transparent),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected
                    ? color
                    : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? color
                      : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
