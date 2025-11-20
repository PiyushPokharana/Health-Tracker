import 'package:flutter/material.dart';
import '../models/daily_record.dart';
import 'package:table_calendar/table_calendar.dart';

class DailySuccessHomePage extends StatefulWidget {
  @override
  _DailySuccessHomePageState createState() => _DailySuccessHomePageState();
}

class _DailySuccessHomePageState extends State<DailySuccessHomePage> {
  List<DailyRecord> records = [];
  int currentStreak = 0;
  int maxStreak = 0;
  int totalActiveDays = 0;
  // Method to add today's record
  void addTodayRecord(bool isSuccess) {
    setState(() {
      records.add(DailyRecord(date: DateTime.now(), isSuccess: isSuccess));
    });
  }

  // Method to show the dialog for adding a delayed entry
  void _showDelayedEntryDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now();
    bool isSuccess = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Enter Delayed Record'),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TableCalendar(
                        focusedDay: selectedDate,
                        firstDay: DateTime.utc(2020, 01, 01),
                        lastDay: DateTime.utc(2050, 12, 31),
                        selectedDayPredicate: (day) =>
                            isSameDay(day, selectedDate),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            selectedDate = selectedDay;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Successful'),
                          Switch(
                            value: isSuccess,
                            onChanged: (bool value) {
                              setState(() {
                                isSuccess = value;
                              });
                            },
                          ),
                          Text('Not Successful'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    addDelayedRecord(selectedDate, isSuccess);
                    Navigator.pop(context);
                  },
                  child: Text('Save'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void addDelayedRecord(DateTime date, bool isSuccess) {
    setState(() {
      bool alreadyExists = records.any((record) =>
          record.date.year == date.year &&
          record.date.month == date.month &&
          record.date.day == date.day);

      if (!alreadyExists) {
        // Add a new delayed record if it doesn't already exist
        records.add(DailyRecord(date: date, isSuccess: isSuccess));
        totalActiveDays = records.length;
        _calculateStreaks();
      } else {
        // Show Snackbar if record already exists
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Record for this date already exists!')),
        );
      }
    });
  }

  void _calculateStreaks() {
    currentStreak = 0;
    maxStreak = 0;
    int tempStreak = 0;

    for (int i = records.length - 1; i >= 0; i--) {
      if (records[i].isSuccess) {
        // Increase streak if the record is successful
        tempStreak++;
        if (tempStreak > maxStreak) {
          maxStreak = tempStreak;
        }
      } else {
        // Reset the current streak after a 'Not Successful' day
        tempStreak = 0;
      }
    }

    currentStreak =
        tempStreak; // Set the current streak to the last tempStreak value
  }

  // Method to show the dialog for editing an existing record
  void _showEditEntryDialog(BuildContext context, DailyRecord record) {
    DateTime editedDate = record.date;
    bool isSuccess = record.isSuccess;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: editedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && picked != editedDate)
                    editedDate = picked;
                },
                child: Text(
                    'Date: ${editedDate.toLocal().toString().split(' ')[0]}'),
              ),
              SwitchListTile(
                title: Text('Was the day successful?'),
                value: isSuccess,
                onChanged: (bool value) {
                  setState(() {
                    isSuccess = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _editEntry(record, editedDate, isSuccess);
                Navigator.pop(context);
              },
              child: Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  // Method to edit an entry
  void _editEntry(DailyRecord record, DateTime editedDate, bool isSuccess) {
    setState(() {
      record.date = editedDate;
      record.isSuccess = isSuccess;
    });
  }

  // Method to delete a record (optional, not part of your request but useful)
  void _deleteRecord(int index) {
    setState(() {
      records.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Success Tracker'),
      ),
      body: ListView.builder(
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return ListTile(
            title: Text(
              '${record.date.toLocal().toString().split(' ')[0]} - ${record.isSuccess ? "Success" : "Not Successful"}',
            ),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _showEditEntryDialog(context, record); // Edit existing record
              },
            ),
            onLongPress: () {
              _deleteRecord(index); // Delete the record on long press
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'success',
            onPressed: () => addTodayRecord(true),
            child: Icon(Icons.check),
            backgroundColor: Colors.green,
            tooltip: 'Mark Today as Successful',
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'not_success',
            onPressed: () => addTodayRecord(false),
            child: Icon(Icons.close),
            backgroundColor: Colors.red,
            tooltip: 'Mark Today as Not Successful',
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'delayed_entry',
            onPressed: () {
              _showDelayedEntryDialog(context);
            },
            child: Icon(Icons.calendar_today),
            backgroundColor: Colors.blue,
            tooltip: 'Add Delayed Entry',
          ),
        ],
      ),
    );
  }
}
