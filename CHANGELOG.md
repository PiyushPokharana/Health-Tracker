# Changelog

All notable changes to the Daily Success Tracker project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2025-11-11

### 🎨 Major Design Overhaul
- Complete theme redesign with premium Navy Blue + Gold + Emerald Green color palette
- Implemented comprehensive dark mode with excellent contrast
- Updated calendar appearance with new color scheme
- Added Material Design 3 principles throughout

### ✨ Added Features
- **Backup & Export System**: Export all habit data to JSON format
- **Import Functionality**: Import previously exported backup files
- **Smart Duplicate Handling**: Automatically handles duplicate habits and records during import
- **Share Integration**: Share exported backup files via system dialog
- **File Picker**: Select backup files from device storage

### 🔧 UI/UX Improvements
- Replaced all emoji icons (✅❌➖) with Material Design icons
- Fixed dark mode visibility issues across all screens
- Enhanced button visibility (Save, Cancel, etc.)
- Improved section header visibility in dark mode
- Made radio button selection dots visible in dark mode
- Enhanced text cursor/caret visibility in text fields
- Added proper ListTile styling with gold icons
- Improved divider visibility between sections

### 📦 Dependencies Added
- `file_picker: ^6.1.1` - For selecting backup files
- `share_plus: ^7.2.1` - For sharing exported data

### 🎯 Accessibility
- Maintained screen reader compatibility
- Ensured all new features are fully accessible
- High contrast maintained in both themes
- Touch targets meet 48dp minimum requirement

### 🐛 Bug Fixes
- Fixed invisible text in dark mode
- Fixed radio button visibility issues
- Fixed text cursor visibility in text fields
- Fixed section headers being invisible in dark mode
- Fixed button text contrast issues

## [2.0.0] - 2025-11

### Added
- Multi-habit tracking support
- Interactive calendar view with table_calendar
- Daily success tracking screen
- Statistics dashboard
- Notes functionality for daily records
- Trash management with soft delete
- Theme switching (Light/Dark/System)
- Settings screen
- SQLite database integration

### Changed
- Upgraded to Material Design 3
- Enhanced UI with premium typography (Inter font)
- Improved navigation and user flow

## [1.0.0] - Initial Release

### Added
- Basic habit tracking functionality
- Simple list view
- Local storage
- Basic theme support

---

## Version Numbering

- **Major version (X.0.0)**: Breaking changes or major feature additions
- **Minor version (0.X.0)**: New features, backward compatible
- **Patch version (0.0.X)**: Bug fixes and minor improvements

## Categories

- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements
