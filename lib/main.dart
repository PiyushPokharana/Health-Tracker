import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/habit_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MultiHabitTrackerApp());
}

class MultiHabitTrackerApp extends StatelessWidget {
  const MultiHabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrap the entire app with MultiProvider for multiple providers
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HabitProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'HTA',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.materialThemeMode,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      // Premium color palette - Navy blue + Gold + Emerald green + Black + White + Platinum silver
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD4AF37), // Gold
        brightness: Brightness.light,
        primary: const Color(0xFF001F3F), // Navy blue - deep and sophisticated
        secondary: const Color(0xFFD4AF37), // Gold - luxury accent
        tertiary: const Color(0xFF50C878), // Emerald green - success and growth
        surface: const Color(0xFFFFFFFF), // Pure white
        background:
            const Color(0xFFE5E4E2), // Platinum silver - elegant background
        onPrimary: const Color(0xFFFFFFFF), // White text on navy
        onSecondary: const Color(0xFF000000), // Black text on gold
        onTertiary: const Color(0xFFFFFFFF), // White text on emerald
        onSurface: const Color(0xFF000000), // Black text on white
        onBackground: const Color(0xFF000000), // Black text on platinum
        error: const Color(0xFFB00020), // Error red
        outline: const Color(0xFF9CA3AF), // Subtle gray outline
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
        elevation: 2,
        shadowColor:
            const Color(0xFF001F3F).withOpacity(0.1), // Navy blue shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: const Color(0xFFE5E4E2)
                .withOpacity(0.8), // Platinum silver border
            width: 1.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: Colors.white,
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
          backgroundColor: const Color(0xFFD4AF37), // Gold background
          foregroundColor: const Color(0xFF000000), // Black text
        ),
      ),
      // Text button styling
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          foregroundColor: const Color(0xFF001F3F), // Navy blue
        ),
      ),
      // Outlined button styling
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          foregroundColor: const Color(0xFF001F3F), // Navy blue
          side: const BorderSide(color: Color(0xFF001F3F), width: 1.5),
        ),
      ),
      // Floating action button styling
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 6,
        backgroundColor: const Color(0xFFD4AF37), // Gold
        foregroundColor: const Color(0xFF000000), // Black text/icon
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // App bar styling
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFF001F3F), // Deep navy
        foregroundColor: const Color(0xFFD4AF37), // Gold text
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)), // Gold icons
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFD4AF37), // Gold title
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
          borderSide: const BorderSide(
              color: Color(0xFFD4AF37), width: 2), // Gold border on focus
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // Text selection and cursor styling for light mode
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF001F3F), // Navy cursor
        selectionColor: Color(0xFFD4AF37), // Gold selection highlight
        selectionHandleColor: Color(0xFF001F3F), // Navy selection handles
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
      // ListTile styling for light theme
      listTileTheme: ListTileThemeData(
        iconColor: const Color(0xFF001F3F), // Navy blue icons
        textColor: const Color(0xFF000000), // Black text
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      // Divider styling
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade300,
        thickness: 1,
        space: 1,
      ),
      // Radio button styling for light theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF001F3F); // Navy when selected
          }
          return Colors.grey.shade400; // Gray when unselected
        }),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      // Dark theme with Navy blue + Gold + Emerald green
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF001F3F), // Deep navy blue
        secondary: Color(0xFFD4AF37), // Gold
        tertiary: Color(0xFF50C878), // Emerald green
        surface: Color(0xFF0A1628), // Very dark navy
        background: Color(0xFF000814), // Near black with navy tint
        onPrimary: Color(0xFFFFFFFF), // White text on navy
        onSecondary: Color(0xFF000000), // Black text on gold
        onTertiary: Color(0xFFFFFFFF), // White text on emerald
        onSurface: Color(0xFFE8E6E3), // Light text on dark surface
        onBackground: Color(0xFFE8E6E3), // Light text on dark background
        error: Color(0xFFEF5350), // Brighter red for visibility
        outline: Color(0xFF4A5568),
      ),
      // Premium typography
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
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
      // Card styling for dark mode
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: const Color(0xFFD4AF37).withOpacity(0.1), // Gold shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFFD4AF37), // Gold border
            width: 1.5,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: const Color(0xFF0A1628), // Dark navy surface
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
          backgroundColor: const Color(0xFFD4AF37), // Gold background
          foregroundColor: const Color(0xFF000000), // Black text for contrast
        ),
      ),
      // Text button styling for dark mode
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          foregroundColor:
              const Color(0xFFFFD700), // Bright gold for visibility
        ),
      ),
      // Outlined button styling for dark mode
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          foregroundColor:
              const Color(0xFFFFD700), // Bright gold for visibility
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
      ),
      // Floating action button styling
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 6,
        backgroundColor: const Color(0xFFFFD700), // Bright gold for dark mode
        foregroundColor: const Color(0xFF000000), // Black text/icon
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // App bar styling
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: const Color(0xFF1A1A1A), // Dark background for app bar
        foregroundColor: Colors.white,
        iconTheme:
            const IconThemeData(color: Color(0xFFFFD700)), // Bright gold icons
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      // Input decoration styling
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0A1628), // Dark navy
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
              color: Color(0xFFD4AF37), width: 1), // Gold border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle:
            const TextStyle(color: Color(0xFFD4AF37)), // Gold label text
        hintStyle:
            const TextStyle(color: Color(0xFF808080)), // Lighter hint text
      ),
      // Text selection and cursor styling for dark mode
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFFD4AF37), // Gold cursor
        selectionColor: Color(0xFFD4AF37), // Gold selection highlight
        selectionHandleColor: Color(0xFFD4AF37), // Gold selection handles
      ),
      // Dialog styling
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        backgroundColor: const Color(0xFF0A1628), // Dark navy
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFD4AF37), // Gold title
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFFE8E6E3),
        ),
      ),
      // Bottom sheet styling
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF0A1628), // Dark navy
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      // ListTile styling for dark theme
      listTileTheme: ListTileThemeData(
        iconColor: const Color(0xFFD4AF37), // Gold icons for visibility
        textColor: const Color(0xFFE8E6E3), // Light text
        subtitleTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: const Color(0xFFB0B0B0), // Lighter gray for subtitles
        ),
      ),
      // Divider styling for dark theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2A3F5F), // Lighter navy for visibility
        thickness: 1,
        space: 1,
      ),
      // Radio button styling for dark theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFFD4AF37); // Gold when selected
          }
          return const Color(0xFF808080); // Gray when unselected
        }),
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
