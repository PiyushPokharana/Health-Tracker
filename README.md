# Daily Success Tracker

A sophisticated Flutter habit tracking application with a premium design aesthetic featuring Navy Blue, Gold, and Emerald Green color scheme. Track multiple habits, visualize your progress with beautiful calendar views, and maintain your success streak with an elegant, user-friendly interface.

## 📱 Features

### Core Functionality
- **Multi-Habit Tracking**: Create and manage unlimited habits
- **Daily Success Tracking**: Mark habits as completed (✓), skipped (○), or failed (✗) for each day
- **Interactive Calendar**: Beautiful calendar view showing your habit completion history
- **Statistics Dashboard**: View completion rates, streaks, and progress analytics
- **Notes & Journal**: Add daily notes to track context and insights
- **Trash Management**: Soft-delete habits with ability to restore or permanently delete

### Data Management
- **Backup & Export**: Export all your habit data to JSON format
- **Import Data**: Import previously exported backups
- **Smart Duplicate Handling**: Automatically handles duplicate habits and records during import
- **SQLite Database**: Reliable local storage for all your data

### User Experience
- **Dark & Light Themes**: Toggle between beautifully designed themes
- **Premium Design**: Navy Blue (#001F3F) + Gold (#D4AF37) + Emerald Green (#50C878) color palette
- **Material 3 Design**: Modern UI following Material Design 3 guidelines
- **Smooth Animations**: Polished transitions and interactions
- **Responsive Layout**: Works seamlessly on different screen sizes

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

**Android APK:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
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
│   ├── habit.dart                     # Habit model
│   ├── habit_record.dart              # Daily habit record model
│   ├── daily_record.dart              # Daily notes model
│   ├── habit_manager.dart             # Habit management logic
│   ├── daily_record_manager.dart      # Notes management logic
│   └── database_helper.dart           # SQLite database operations
├── providers/                         # State management
│   ├── habit_provider.dart            # Habit state provider
│   └── theme_provider.dart            # Theme state provider
├── screens/                           # UI screens
│   ├── home_screen.dart               # Main screen with habit list
│   ├── habit_detail_screen.dart       # Individual habit details & calendar
│   ├── daily_success_screen.dart      # Daily tracking interface
│   ├── settings_screen.dart           # App settings
│   ├── trash_screen.dart              # Deleted habits management
│   ├── notes_list_screen.dart         # Daily notes list
│   └── backup_screen.dart             # Backup & export functionality
├── widgets/                           # Reusable UI components
│   ├── statistics_widget.dart         # Statistics display
│   └── day_detail_bottom_sheet.dart   # Day detail modal
└── services/                          # Business services
    └── backup_service.dart            # Import/export functionality
```

## 🎯 Usage Guide

### Creating a Habit
1. Tap the **+** button on the home screen
2. Enter your habit name
3. Tap **Save** to create the habit

### Tracking Daily Progress
1. Tap **Today's Success** on the home screen
2. For each habit, select:
   - ✓ **Completed**: Successfully did the habit
   - ○ **Skipped**: Intentionally skipped
   - ✗ **Failed**: Missed the habit
3. Tap **Save** to record your progress

### Viewing Statistics
- Tap on any habit card to see detailed statistics
- View calendar with color-coded days
- See completion rates and streaks
- Scroll through historical data

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
- **habits** table: Stores habit information
- **habit_records** table: Stores daily completion records
- **daily_records** table: Stores daily notes

## 🧪 Testing

Run tests with:
```bash
flutter test
```

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
- Material Design for design guidelines
- All open-source package contributors

## 📧 Support

For support, please open an issue in the GitHub repository or contact the maintainer.

---

**Version**: 3.0.0+10  
**Last Updated**: November 2025  
**Flutter Version**: 3.6.1+
