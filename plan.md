# Multi-Habit Tracker - Implementation Plan

## Project Overview
Transform the current single-habit "Daily Success Tracker" into a comprehensive multi-habit tracker as specified in PV0.txt.

---

## Phase 1: Database & Data Models (Foundation) ✅ **COMPLETE**

### 1.1 Database Schema Design ✅
- [x] Create new database schema with two tables:
  - **Habits Table**: `id`, `name`, `createdAt`, `isDeleted`, `deletedAt`
  - **HabitRecords Table**: `id`, `habitId`, `date`, `status`, `note`
- [x] Plan data migration from existing `DailyRecords` table
- [x] Design database version upgrade path

### 1.2 Create New Model Classes ✅
- [x] Create `lib/models/habit.dart`
  - Properties: id, name, createdAt, isDeleted, deletedAt
  - Methods: toMap(), fromMap(), copyWith()
- [x] Create `lib/models/habit_record.dart`
  - Create enum: `HabitStatus` (complete, missed, skipped)
  - Properties: id, habitId, date, status, note
  - Methods: toMap(), fromMap(), copyWith()

### 1.3 Update Database Helper ✅
- [x] Update `lib/models/database_helper.dart`
  - [x] Add `_onCreate` for new tables
  - [x] Add `_onUpgrade` for migration
  - [x] Implement habit CRUD operations
  - [x] Implement habit record CRUD operations
  - [x] Add method to get all non-deleted habits
  - [x] Add method to get deleted habits (for trash)
  - [x] Add method to soft-delete habit (via updateHabit)
  - [x] Add method to restore habit (via updateHabit)
  - [x] Add method to permanently delete habit

### 1.4 Create Habit Manager ✅
- [x] Create `lib/models/habit_manager.dart`
  - [x] Load all habits
  - [x] Add/edit/delete habit
  - [x] Load records for specific habit
  - [x] Calculate streaks per habit
  - [x] Calculate statistics per habit
  - [x] Handle trash cleanup (30-day auto-delete)

---

## Phase 2: Home Screen (Habit List)

### 2.1 Create Home Screen UI
- [ ] Create `lib/screens/home_screen.dart`
  - [ ] Design app bar with title and settings icon
  - [ ] Create ListView/GridView for habits
  - [ ] Show empty state when no habits exist
  - [ ] Add FloatingActionButton (+) to add new habit

### 2.2 Create Habit List Item Widget
- [ ] Create `lib/widgets/habit_list_tile.dart`
  - [ ] Display habit name
  - [ ] Display current streak with fire emoji (🔥 X days)
  - [ ] Handle tap (navigate to HBTC screen)
  - [ ] Handle long-press (enter selection mode)
  - [ ] Show checkbox in selection mode

### 2.3 Implement Add/Edit Habit Functionality
- [ ] Create `lib/screens/add_edit_habit_screen.dart` or dialog
  - [ ] Text field for habit name
  - [ ] Validation (non-empty, unique name)
  - [ ] Save button
  - [ ] Cancel button

### 2.4 Implement Selection Mode
- [ ] Add selection mode state to HomeScreen
- [ ] Create `lib/widgets/selection_app_bar.dart`
  - [ ] Show selected count
  - [ ] Delete button (moves to trash)
  - [ ] Select All button
  - [ ] Edit/Rename button (enabled only for 1 selected)
  - [ ] Cancel button
- [ ] Handle multi-select logic
- [ ] Handle delete action (soft-delete)
- [ ] Handle rename action

---

## Phase 3: Habit Detail Screen (HBTC)

### 3.1 Create Habit Detail Screen Structure
- [ ] Create `lib/screens/habit_detail_screen.dart`
  - [ ] App bar with habit name and back button
  - [ ] Streak display at top (🔥 current streak)
  - [ ] Calendar section
  - [ ] Statistics section
  - [ ] Optional: Bottom navigation for Calendar/Stats tabs

### 3.2 Implement Calendar View
- [ ] Integrate TableCalendar widget
- [ ] Create custom day builders for three statuses:
  - [ ] Complete: Green with ✅
  - [ ] Missed: Red/Gray with ❌
  - [ ] Skipped: Yellow/Gray with ➖
- [ ] Handle day tap to open edit menu
- [ ] Load records for selected habit
- [ ] Display current month initially

### 3.3 Implement Day Edit Functionality
- [ ] Create `lib/widgets/day_detail_bottom_sheet.dart`
  - [ ] Show selected date
  - [ ] Status selector (3 options: Complete/Missed/Skipped)
  - [ ] Note text field with 📝 icon
  - [ ] Save button
  - [ ] Delete/Clear button
  - [ ] Cancel button
- [ ] Save/update record in database
- [ ] Refresh calendar after save

### 3.4 Implement Statistics Section
- [ ] Create `lib/widgets/statistics_widget.dart` or separate screen
  - [ ] Current streak vs best streak comparison
  - [ ] Total completion percentage
  - [ ] Total days tracked
  - [ ] Success rate (complete / total)
  - [ ] Optional: Weekly/monthly breakdown
  - [ ] Optional: Charts/graphs

---

## Phase 4: Three-Status System

### 4.1 Update Status Logic
- [ ] Create `HabitStatus` enum with three values
- [ ] Update all record operations to use enum
- [ ] Update UI to show three different colors/icons

### 4.2 Update Streak Calculation
- [ ] Modify streak logic to:
  - [ ] Count "Complete" as streak continuation
  - [ ] Break streak on "Missed"
  - [ ] Ignore "Skipped" (don't break or continue streak)
- [ ] Test edge cases

### 4.3 Update Statistics Calculations
- [ ] Calculate completion percentage (complete / (complete + missed))
- [ ] Exclude skipped days from percentage calculation
- [ ] Update all stats displays

---

## Phase 5: Notes System

### 5.1 Implement Note Storage
- [ ] Ensure `note` field exists in HabitRecords table
- [ ] Add note parameter to record CRUD operations

### 5.2 Implement Note UI
- [ ] Add note text field to day detail bottom sheet
- [ ] Show note icon (📝 or 💬) on calendar days with notes
- [ ] Display existing note when editing day
- [ ] Allow clearing/deleting notes

### 5.3 Optional: Note Viewing
- [ ] Create note viewer widget
- [ ] Show notes in a list view
- [ ] Search/filter notes

---

## Phase 6: Trash & Restore System

### 6.1 Create Trash Screen
- [ ] Create `lib/screens/trash_screen.dart`
  - [ ] List all deleted habits
  - [ ] Show deletion date
  - [ ] Restore button per habit
  - [ ] Permanent delete button
  - [ ] Empty trash message

### 6.2 Implement Soft Delete
- [ ] Update delete operation to set `isDeleted = 1`
- [ ] Set `deletedAt` timestamp
- [ ] Filter deleted habits from home screen

### 6.3 Implement Restore
- [ ] Create restore method in HabitManager
- [ ] Set `isDeleted = 0` and clear `deletedAt`
- [ ] Refresh home screen after restore

### 6.4 Implement 30-Day Auto-Delete
- [ ] Create cleanup method in HabitManager
- [ ] Check trash on app launch
- [ ] Permanently delete habits older than 30 days
- [ ] Optional: Show notification before auto-delete

### 6.5 Add Trash to Settings
- [ ] Create `lib/screens/settings_screen.dart`
  - [ ] Link to trash screen
  - [ ] Other settings (theme, notifications, etc.)
- [ ] Add settings icon to home screen app bar

---

## Phase 7: Data Migration

### 7.1 Plan Migration Strategy
- [ ] Decide how to handle existing DailyRecords data
- [ ] Option 1: Create default "Daily Success" habit with old data
- [ ] Option 2: Prompt user to name their first habit
- [ ] Option 3: Start fresh (export old data first)

### 7.2 Implement Migration
- [ ] Write database upgrade script
- [ ] Test migration with sample data
- [ ] Handle edge cases (empty database, corrupted data)

### 7.3 Test Migration
- [ ] Test with existing user data
- [ ] Verify streaks are preserved
- [ ] Verify no data loss

---

## Phase 8: State Management (Optional but Recommended)

### 8.1 Choose State Management Solution
- [ ] Evaluate options: Provider, Riverpod, Bloc, GetX
- [ ] Decision: ________________

### 8.2 Implement State Management
- [ ] Set up provider/state manager
- [ ] Create HabitProvider or equivalent
- [ ] Refactor screens to use state management
- [ ] Remove manual setState() calls where appropriate

---

## Phase 9: UI/UX Polish

### 9.1 Design Improvements
- [ ] Choose color scheme for three statuses
- [ ] Design app icon and splash screen
- [ ] Implement Material 3 theme
- [ ] Add animations and transitions
- [ ] Improve empty states

### 9.2 User Experience
- [ ] Add loading indicators
- [ ] Add error handling and user feedback
- [ ] Implement undo for delete operations
- [ ] Add confirmation dialogs for destructive actions
- [ ] Add haptic feedback for interactions

### 9.3 Accessibility
- [ ] Add semantic labels
- [ ] Test with screen readers
- [ ] Ensure sufficient color contrast
- [ ] Add text scaling support

---

## Phase 10: Testing & Bug Fixes

### 10.1 Unit Tests
- [ ] Test HabitManager methods
- [ ] Test streak calculations
- [ ] Test database operations
- [ ] Test date handling

### 10.2 Widget Tests
- [ ] Test home screen
- [ ] Test habit detail screen
- [ ] Test day edit bottom sheet
- [ ] Test selection mode

### 10.3 Integration Tests
- [ ] Test complete user flows
- [ ] Test data persistence
- [ ] Test migration

### 10.4 Manual Testing
- [ ] Test on multiple devices/screen sizes
- [ ] Test with different data scenarios
- [ ] Test edge cases (empty lists, long names, etc.)
- [ ] Performance testing with many habits

---

## Phase 11: Documentation & Deployment

### 11.1 Code Documentation
- [ ] Add doc comments to public APIs
- [ ] Document data models
- [ ] Create README.md with setup instructions

### 11.2 User Documentation
- [ ] Create user guide
- [ ] Add in-app help/tutorial
- [ ] Create demo video/screenshots

### 11.3 Deployment Preparation
- [ ] Update version number
- [ ] Test release build
- [ ] Prepare app store assets
- [ ] Write release notes

---

## Technical Decisions To Make

| Decision | Options | Choice | Notes |
|----------|---------|--------|-------|
| State Management | Provider / Riverpod / Bloc / GetX / setState | _______ | Consider app complexity |
| Navigation | Push/Pop / Named Routes / Navigator 2.0 | _______ | Keep it simple initially |
| 30-Day Delete | On app launch / Background task | _______ | WorkManager for background |
| Migration | Auto-migrate / User prompt / Fresh start | _______ | Best UX approach |
| Theme | Material 2 / Material 3 / Custom | _______ | Material 3 recommended |

---

## Estimated Timeline

| Phase | Estimated Hours | Status |
|-------|----------------|--------|
| Phase 1: Database & Models | 8-12 hours | ✅ **COMPLETE** |
| Phase 2: Home Screen | 10-15 hours | ⬜ Not Started |
| Phase 3: Habit Detail Screen | 12-18 hours | ⬜ Not Started |
| Phase 4: Three-Status System | 4-6 hours | ✅ **COMPLETE** (Done in Phase 1) |
| Phase 5: Notes System | 4-6 hours | ✅ **COMPLETE** (Done in Phase 1) |
| Phase 6: Trash System | 6-8 hours | ⬜ Not Started |
| Phase 7: Data Migration | 4-6 hours | ✅ **COMPLETE** (Done in Phase 1) |
| Phase 8: State Management | 8-12 hours | ⬜ Not Started |
| Phase 9: UI/UX Polish | 10-15 hours | ⬜ Not Started |
| Phase 10: Testing | 8-12 hours | ⬜ Not Started |
| Phase 11: Documentation | 4-6 hours | ⬜ Not Started |
| **TOTAL** | **78-116 hours** | **~24-36 hours completed** |

---

## Quick Reference: File Structure

```
lib/
├── main.dart (update entry point)
├── models/
│   ├── habit.dart (NEW)
│   ├── habit_record.dart (NEW)
│   ├── habit_manager.dart (NEW)
│   ├── database_helper.dart (MODIFY - major changes)
│   ├── daily_record.dart (REMOVE or repurpose)
│   └── daily_record_manager.dart (REMOVE)
├── screens/
│   ├── home_screen.dart (NEW - list of habits)
│   ├── habit_detail_screen.dart (NEW - HBTC)
│   ├── add_edit_habit_screen.dart (NEW)
│   ├── settings_screen.dart (NEW)
│   ├── trash_screen.dart (NEW)
│   └── daily_success_screen.dart (REMOVE)
└── widgets/
    ├── habit_list_tile.dart (NEW)
    ├── selection_app_bar.dart (NEW)
    ├── day_detail_bottom_sheet.dart (NEW)
    ├── statistics_widget.dart (NEW)
    ├── streak_display.dart (NEW)
    └── status_selector.dart (NEW)
```

---

## Notes & Ideas

- Consider adding habit categories (Health, Productivity, etc.)
- Consider adding habit icons or colors for personalization
- Consider adding reminders/notifications
- Consider adding widgets for home screen
- Consider adding export/backup functionality
- Consider adding cloud sync in future versions
- Consider adding social features (sharing streaks)

---

## Current Status: Phase 1 Complete ✅

**Completed:** Phase 1 - Database & Data Models (All tasks finished and committed to GitHub)

**Next Step:** Begin Phase 2 - Home Screen (Habit List)

**Last Updated:** November 8, 2025
