# HTA - Habit Tracking App

A sophisticated Flutter habit tracking application with advanced timer functionality and a premium design aesthetic. Track multiple habits with session-based timers, visualize your progress with beautiful calendar views, and maintain your success streak with an elegant, user-friendly interface.

[![Flutter](https://img.shields.io/badge/Flutter-3.6.1+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## ✨ Features

### 🎯 Advanced Timer System
- **Persistent Stopwatch**: Timer continues running even when phone is locked, app is minimized, or device is restarted
- **Background Persistence**: Database-backed timer state ensures accurate time tracking across app lifecycle
- **Session Management**: Track multiple timed sessions per habit with start/end timestamps
- **Persistent Timer Bar**: Always-visible timer bar at bottom of screen showing active timers
- **Pause/Resume**: Full control over timer state with visual indicators

### 📊 Habit Tracking
- **Multi-Habit Management**: Create and track unlimited habits simultaneously
- **Daily Success Marking**: Mark habits as completed (✓), skipped (○), or failed (✗) for each day
- **Interactive Calendar**: Beautiful calendar view showing your habit completion history
- **Streak Tracking**: Visualize current and maximum streaks
- **Statistics Dashboard**: View completion rates, trends, and progress analytics

### ⏱️ Session Logs
- **Dedicated Session Viewer**: Full-screen session log with date navigation
- **Date Filtering**: Quickly jump to any date with calendar picker
- **Session Details**: View start time, end time, and duration for each session
- **Delete Sessions**: Remove individual sessions with confirmation
- **Empty State Handling**: Clear messaging when no sessions exist

### ⚙️ Smart Settings
- **Timer ON/OFF Toggle**: Enable/disable timer functionality per habit
- **Session Deletion Warning**: Confirmation dialog when disabling timer (erases all session data)
- **7-Day Preference Memory**: "Don't show again" option for power users
- **Multiple Sessions**: Automatic support when timer is enabled

### 💾 Data Management
- **SQLite Database**: Reliable local storage for habits, records, and sessions
- **Backup & Export**: Export all your data to JSON format
- **Import Data**: Restore from previously exported backups
- **Smart Duplicate Handling**: Automatic deduplication during import
- **Soft Delete**: Move habits to trash with ability to restore

### 🎨 Premium User Experience
- **Dark & Light Themes**: Seamless theme switching with WCAG AA contrast compliance
- **Material 3 Design**: Modern UI following latest Material Design guidelines
- **Navy Blue + Gold + Emerald**: Premium color palette (#001F3F, #D4AF37, #50C878)
- **Smooth Animations**: Polished fade and slide transitions
- **Responsive Layout**: Optimized for phones, tablets, and emulators
- **Haptic Feedback**: Tactile responses for key interactions

## 🎨 Design Philosophy

The app features a premium color scheme inspired by sophistication and success:
- **Navy Blue** (#001F3F): Deep, professional primary color
- **Gold** (#D4AF37): Luxury accent representing achievements
- **Emerald Green** (#50C878): Success and growth
- **Platinum Silver** (#E5E4E2): Elegant backgrounds
- **Black & White**: Classic contrast and clarity

Both light and dark themes are carefully crafted with optimal contrast ratios for excellent visibility and accessibility.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.6.1 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- An Android or iOS device/emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/PiyushPokharana/Health-Tracker.git
   cd daily_success_tracker_1
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

**Android App Bundle (for Google Play):**
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

**Android APK (universal - all devices):**
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**Android APK (split by architecture - smaller files):**
```bash
flutter build apk --release --split-per-abi
```
Output:
- `app-armeabi-v7a-release.apk` (Old Android 5-8)
- `app-arm64-v8a-release.apk` (New Android 8+)
- `app-x86_64-release.apk` (Emulators/Tablets)

**iOS:**
```bash
flutter build ios --release
# or for App Store
flutter build ipa --release
```

## 📦 Dependencies

### Core Packages
- **sqflite** (^2.3.0): Local SQLite database
- **path_provider** (^2.1.2): Access to file system paths
- **provider** (^6.1.1): State management solution
- **shared_preferences** (^2.2.2): Persistent key-value storage

### UI & Design
- **google_fonts** (^6.1.0): Premium Inter font family
- **table_calendar** (^3.1.0): Interactive calendar widget
- **intl** (^0.19.0): Internationalization and date formatting

### Features
- **file_picker** (^6.1.1): File selection for backup imports
- **share_plus** (^7.2.1): Share exported backup files

### Development
- **flutter_lints** (^5.0.0): Recommended linting rules
- **mockito** (^5.4.4): Testing framework
- **flutter_launcher_icons** (^0.13.1): App icon generation

## 📂 Project Structure

```
lib/
├── main.dart                          # App entry point & theme configuration
├── models/                            # Data models and business logic
│   ├── habit.dart                     # Habit model with timer settings
│   ├── habit_record.dart              # Daily habit record model
│   ├── habit_session.dart             # Timed session model
│   ├── daily_record.dart              # Daily notes model
│   ├── habit_manager.dart             # Habit management logic
│   ├── daily_record_manager.dart      # Notes management logic
│   └── database_helper.dart           # SQLite database operations
├── providers/                         # State management
│   ├── habit_provider.dart            # Habit state & timer management
│   └── theme_provider.dart            # Theme state provider
├── screens/                           # UI screens
│   ├── home_screen.dart               # Main screen with habit list
│   ├── habit_detail_screen.dart       # Habit details, calendar & stopwatch
│   ├── daily_success_screen.dart      # Daily tracking interface
│   ├── settings_screen.dart           # App settings
│   ├── trash_screen.dart              # Deleted habits management
│   ├── notes_list_screen.dart         # Daily notes list
│   └── backup_screen.dart             # Backup & export functionality
├── widgets/                           # Reusable UI components
│   ├── statistics_widget.dart         # Statistics display
│   ├── day_detail_bottom_sheet.dart   # Day detail modal
│   └── persistent_timer_bar.dart      # Bottom timer bar
└── services/                          # Business services
    ├── backup_service.dart            # Import/export functionality
    └── preferences_service.dart       # User preferences storage
```

## 🎯 Usage Guide

### Creating a Habit
1. Tap the **+ Add Habit** button on the home screen
2. Enter your habit name (e.g., "Exercise", "Read", "Meditate")
3. Tap **Add** to create the habit

### Using the Timer
1. Open a habit from the home screen
2. Tap **Start** button to begin timer
3. Timer persists even when app is closed or phone is locked
4. Use **Pause/Resume** to control the timer
5. Tap **Stop & Save** to save the session
6. View all sessions in **Session Logs** screen

### Managing Timer Settings
1. Open habit detail screen
2. Tap **Settings** icon (⚙️)
3. Toggle **Timer ON/OFF**
   - Turning OFF shows warning (erases all session data)
   - Check "Don't show again for 7 days" for power users
4. Multiple sessions automatically enabled when timer is ON

### Viewing Session Logs
1. Open habit detail screen
2. Tap **History** icon (📊) in top-right
3. Use date navigation arrows or calendar picker
4. Tap delete icon to remove individual sessions
5. Sessions show start time, end time, and duration

### Tracking Daily Progress
1. Tap a habit on the home screen to open detail view
2. Tap on calendar dates to mark:
   - ✓ **Completed**: Successfully did the habit
   - ○ **Skipped**: Intentionally skipped
   - ✗ **Failed**: Missed the habit
3. Add optional notes for context
4. Progress automatically saved

### Viewing Statistics
- Open any habit to see detailed statistics
- Interactive calendar with color-coded days
- Current streak and maximum streak display
- Completion rates and trends
- Recent activity sparkline

### Managing Backups
1. Go to **Settings** → **Backup & Export**
2. **Export Data**: Creates a JSON backup and opens share dialog
3. **Import Backup**: Select a previously exported file to restore data

### Switching Themes
- Go to **Settings** → **Theme**
- Choose between:
  - 🌞 Light Mode
  - 🌙 Dark Mode
  - ⚙️ System Default

## 🔧 Configuration

### App Icon
Custom app icon can be generated using:
```bash
flutter pub run flutter_launcher_icons
```

### Database
The app uses SQLite for local data storage. Database schema includes:
- **Habits** table: Stores habit information with timer settings
- **HabitRecords** table: Stores daily completion records
- **HabitSessions** table: Stores timed sessions with start/end timestamps
- **DailyRecords** table: Stores daily notes and journal entries

All data is stored locally on device with no cloud sync (privacy-first design).

## 🧪 Testing

Run tests with:
```bash
flutter test
```

## 🔒 Privacy & Security

- ✅ **100% Local Storage**: All data stored on device using SQLite
- ✅ **No Cloud Sync**: Your data never leaves your device
- ✅ **No Analytics**: No tracking or telemetry
- ✅ **No Ads**: Clean, distraction-free experience
- ✅ **Open Source**: Full transparency of codebase

## 🐛 Known Issues & Limitations

- Timer notifications not yet implemented (planned for v4.0)
- Cloud sync not available (local storage only)
- Import/export requires manual file management

## 🗺️ Roadmap

- [ ] Push notifications for timer completion
- [ ] Habit categories and tags
- [ ] Weekly/monthly goal setting
- [ ] Data visualization charts
- [ ] Cloud backup option (optional)
- [ ] Widget support for home screen
- [ ] Reminder notifications

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Author

**Piyush Pokharana**
- GitHub: [@PiyushPokharana](https://github.com/PiyushPokharana)
- Repository: [Health-Tracker](https://github.com/PiyushPokharana/Health-Tracker)

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design 3 for design guidelines
- All open-source package contributors
- Community feedback and feature suggestions

## 📧 Support

For support, feature requests, or bug reports:
- Open an issue in the [GitHub repository](https://github.com/PiyushPokharana/Health-Tracker/issues)
- Check existing issues before creating new ones
- Provide detailed information and steps to reproduce bugs

---

**Version**: 3.1.3+14  
**Last Updated**: November 2025  
**Flutter Version**: 3.6.1+  
**Platform Support**: Android 5.0+, iOS 11+, Windows, macOS, Linux, Web
