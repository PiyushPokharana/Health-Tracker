import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/habit_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MultiHabitTrackerApp());
}

class MultiHabitTrackerApp extends StatelessWidget {
  const MultiHabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap the entire app with ChangeNotifierProvider
    // This makes HabitProvider available to all widgets in the tree
    return ChangeNotifierProvider(
      create: (_) => HabitProvider(),
      child: MaterialApp(
        title: 'Multi-Habit Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          // Premium color palette - Dark charcoal with amber/gold accents
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFF59E0B), // Amber-500
            brightness: Brightness.light,
            primary: const Color(0xFF1F2937), // Gray-800 - sophisticated dark
            secondary: const Color(0xFFF59E0B), // Amber-500 - premium gold
            tertiary: const Color(0xFF10B981), // Emerald-500 for success
            surface: const Color(0xFFFAFAFA), // Off-white
            background: const Color(0xFFF5F5F5), // Light gray
          ),
          // Premium typography using Inter font family
          textTheme: GoogleFonts.interTextTheme(
            ThemeData.light().textTheme,
          ).copyWith(
            displayLarge: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            displayMedium: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            displaySmall: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
            ),
            headlineLarge: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
            ),
            headlineMedium: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            titleMedium: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            bodyLarge: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
            bodyMedium: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          // Premium card styling with subtle shadows
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
          // Elevated button styling
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Floating action button styling
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          // App bar styling
          appBarTheme: AppBarTheme(
            elevation: 0,
            centerTitle: false,
            backgroundColor: const Color(0xFF1F2937),
            foregroundColor: Colors.white,
            titleTextStyle: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          // Input decoration styling
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          // Dialog styling
          dialogTheme: DialogTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
          ),
          // Bottom sheet styling
          bottomSheetTheme: const BottomSheetThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

// OLD CODE BELOW - Keep for reference, remove later
/*
class DailySuccessHomePage extends StatefulWidget {
  final DailyRecordManager recordManager;

  const DailySuccessHomePage({Key? key, required this.recordManager})
      : super(key: key);

  @override
  _DailySuccessHomePageState createState() => _DailySuccessHomePageState();
}

class _DailySuccessHomePageState extends State<DailySuccessHomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  void _addOrEditRecord(BuildContext context,
      {DateTime? date, DailyRecord? record, bool? isSuccess}) async {
    DateTime selectedDate = date ?? _selectedDay ?? DateTime.now();
    bool newIsSuccess = isSuccess ?? record?.isSuccess ?? true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(record == null ? 'Add Record' : 'Edit Record'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                  ElevatedButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.utc(2020, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: const Text('Select Date'),
                  ),
                  SwitchListTile(
                    title: const Text('Was the day successful?'),
                    value: newIsSuccess,
                    onChanged: (bool value) {
                      setState(() {
                        newIsSuccess = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedDate.isAfter(DateTime.now())) {
                      //  Prevent adding future entries
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Cannot add entries for future dates."),
                        ),
                      );
                      return;
                    }
                    if (record == null) {
                      await widget.recordManager
                          .addRecord(selectedDate, newIsSuccess);
                    } else {
                      await widget.recordManager
                          .editRecord(selectedDate, newIsSuccess);
                    }
                    Navigator.pop(context);
                    setState(() {}); //  Refresh UI after add/edit
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hasTodayEntry = widget.recordManager.hasRecordForDate(DateTime.now());
    bool isTodaySuccessful = false;
    if (hasTodayEntry) {
      isTodaySuccessful = widget.recordManager.records
          .firstWhere((r) => tc.isSameDay(r.date, DateTime.now()))
          .isSuccess;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Success Tracker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //  Current Streak Display (Modified)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hasTodayEntry && isTodaySuccessful
                        ? '❤️'
                        : '🤍', //  Filled or outlined heart based on today's success
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.recordManager.currentStreak}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            tc.TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2050, 12, 31),
              selectedDayPredicate: (day) => tc.isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarBuilders: tc.CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  if (widget.recordManager.hasRecordForDate(day)) {
                    final record = widget.recordManager.records
                        .firstWhere((r) => tc.isSameDay(r.date, day));
                    Color color = record.isSuccess ? Colors.green : Colors.grey;
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            day.day.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                },
                selectedBuilder: (context, day, focusedDay) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(4.0),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          day.day.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(4.0),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          day.day.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Max Streak: ${widget.recordManager.maxStreak} days',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Total Active Days: ${widget.recordManager.activeDays} days',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: widget.recordManager.records
                    .where((record) => tc.isSameDay(record.date, _selectedDay))
                    .length,
                itemBuilder: (context, index) {
                  final record = widget.recordManager.records
                      .where(
                          (record) => tc.isSameDay(record.date, _selectedDay))
                      .toList()[index];
                  return ListTile(
                    title: Text(
                      '${DateFormat('yyyy-MM-dd').format(record.date)} - ${record.isSuccess ? "Success" : "Not Successful"}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _addOrEditRecord(context, record: record),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            deleteRecord(record.date);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'success',
            onPressed: () => _addOrEditRecord(context,
                date: DateTime.now(), isSuccess: true),
            backgroundColor: Colors.green,
            tooltip: 'Mark Today as Successful',
            child: const Icon(Icons.check),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'not_success',
            onPressed: () => _addOrEditRecord(context,
                date: DateTime.now(), isSuccess: false),
            backgroundColor: Colors.red,
            tooltip: 'Mark Today as Not Successful',
            child: const Icon(Icons.close),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'delayed_entry',
            onPressed: () {
              _showDelayedEntryDialog(context);
            },
            backgroundColor: Colors.blue,
            tooltip: 'Add Delayed Entry',
            child: const Icon(Icons.calendar_today),
          ),
        ],
      ),
    );
  }

  Future<void> deleteRecord(DateTime date) async {
    await widget.recordManager.deleteRecord(date);
    setState(() {});
  }

  void _showDelayedEntryDialog(BuildContext context) {
    DateTime selectedDate = _selectedDay ?? DateTime.now();
    bool newIsSuccess = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Delayed Entry'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}"),
                  ElevatedButton(
                    onPressed: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.utc(2020, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null && picked != selectedDate) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: const Text('Select Date'),
                  ),
                  SwitchListTile(
                    title: const Text('Was the day successful?'),
                    value: newIsSuccess,
                    onChanged: (bool value) {
                      setState(() {
                        newIsSuccess = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedDate.isAfter(DateTime.now())) {
                      //  Prevent adding future entries
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Cannot add entries for future dates."),
                        ),
                      );
                      return;
                    }
                    await widget.recordManager
                        .addRecord(selectedDate, newIsSuccess);
                    Navigator.pop(context);
                    setState(() {}); //  Refresh UI after adding
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
*/
