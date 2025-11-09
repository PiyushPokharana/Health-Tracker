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

## Phase 2: Home Screen (Habit List) ✅ **COMPLETE**

### 2.1 Create Home Screen UI ✅
- [x] Create `lib/screens/home_screen.dart`
  - [x] Design app bar with title and settings icon
  - [x] Create ListView for habits
  - [x] Show empty state when no habits exist
  - [x] Add FloatingActionButton (+) to add new habit

### 2.2 Create Habit List Item Widget ✅
- [x] Habit list tiles implemented inline in HomeScreen
  - [x] Display habit name
  - [x] Display current streak with fire emoji (🔥 X days)
  - [x] Handle tap (navigate to HBTC screen - placeholder)
  - [x] Handle long-press (enter selection mode)
  - [x] Show checkbox in selection mode

### 2.3 Implement Add/Edit Habit Functionality ✅
- [x] Add/Edit dialog implemented in HomeScreen
  - [x] Text field for habit name
  - [x] Validation (non-empty)
  - [x] Save button
  - [x] Cancel button

### 2.4 Implement Selection Mode ✅
- [x] Add selection mode state to HomeScreen
- [x] Selection app bar implemented
  - [x] Show selected count
  - [x] Delete button (moves to trash)
  - [x] Select All button
  - [x] Edit/Rename button (enabled only for 1 selected)
  - [x] Cancel button
- [x] Handle multi-select logic
- [x] Handle delete action (soft-delete)
- [x] Handle rename action

---

## Phase 3: Habit Detail Screen (HBTC) ✅ **COMPLETE**

### 3.1 Create Habit Detail Screen Structure ✅
- [x] Create `lib/screens/habit_detail_screen.dart`
  - [x] App bar with habit name and back button
  - [x] Streak display at top (🔥 current streak) with gradient design
  - [x] Calendar section with TableCalendar
  - [x] Statistics section (quick stats + detailed modal)
  - [x] Legend for status colors

### 3.2 Implement Calendar View ✅
- [x] Integrate TableCalendar widget
- [x] Create custom day builders for three statuses:
  - [x] Complete: Green with ✅
  - [x] Missed: Red with ❌
  - [x] Skipped: Yellow/Amber with ➖
- [x] Handle day tap to open edit menu
- [x] Load records for selected habit
- [x] Display current month initially
- [x] Show note indicator (white dot) on days with notes
- [x] Highlight today with blue border

### 3.3 Implement Day Edit Functionality ✅
- [x] Create `lib/widgets/day_detail_bottom_sheet.dart`
  - [x] Show selected date (with "Today" indicator)
  - [x] Status selector (3 buttons: Complete/Missed/Skipped)
  - [x] Note text field with 📝 icon (200 char limit)
  - [x] Save button with loading state
  - [x] Delete button with confirmation
  - [x] Cancel button
- [x] Save/update record in database
- [x] Refresh calendar after save
- [x] Prevent future dates from being marked

### 3.4 Implement Statistics Section ✅
- [x] Create `lib/widgets/statistics_widget.dart` as draggable modal
  - [x] Current streak vs best streak comparison
  - [x] Total completion percentage with visual progress bar
  - [x] Total days tracked
  - [x] Success rate (complete / total)
  - [x] Breakdown by status (complete/missed/skipped counts)
  - [x] Motivational messages based on completion rate
  - [x] Color-coded progress indicator

---

## Phase 4: Three-Status System ✅ **COMPLETE** (Implemented in Phase 1 & 3)

### 4.1 Update Status Logic ✅
- [x] Create `HabitStatus` enum with three values (complete, missed, skipped)
- [x] Update all record operations to use enum
- [x] Update UI to show three different colors/icons
  - [x] Complete: Green circle with ✅
  - [x] Missed: Red circle with ❌
  - [x] Skipped: Amber/Yellow circle with ➖

### 4.2 Update Streak Calculation ✅
- [x] Modify streak logic to:
  - [x] Count "Complete" as streak continuation
  - [x] Break streak on "Missed"
  - [x] Ignore "Skipped" (don't break or continue streak)
- [x] Implemented in `habit_manager.dart` getCurrentStreak() method
- [x] Tested with multiple scenarios

### 4.3 Update Statistics Calculations ✅
- [x] Calculate completion percentage (completedCount / totalRecords * 100)
- [x] Track all three statuses separately (completedCount, missedCount, skippedCount)
- [x] Display all stats in statistics widget
- [x] Visual progress bar based on completion rate

---

## Phase 5: Notes System ✅ **COMPLETE** (Implemented in Phase 1 & 3)

### 5.1 Implement Note Storage ✅
- [x] Ensure `note` field exists in HabitRecords table
- [x] Add note parameter to record CRUD operations
- [x] Database schema includes `note TEXT` field
- [x] HabitManager handles note saving/updating

### 5.2 Implement Note UI ✅
- [x] Add note text field to day detail bottom sheet
- [x] Show note indicator (white dot) on calendar days with notes
- [x] Display existing note when editing day
- [x] Allow clearing/deleting notes
- [x] 200 character limit on notes
- [x] Note icon (📝) shown in text field

### 5.3 Optional: Note Viewing
- [x] Notes displayed in bottom sheet when tapping day
- [x] Notes editable at any time
- [ ] Show notes in a list view (Future enhancement)
- [ ] Search/filter notes (Future enhancement)

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
| Phase 2: Home Screen | 10-15 hours | ✅ **COMPLETE** |
| Phase 3: Habit Detail Screen | 12-18 hours | ✅ **COMPLETE** |
| Phase 4: Three-Status System | 4-6 hours | ✅ **COMPLETE** (Done in Phase 1) |
| Phase 5: Notes System | 4-6 hours | ✅ **COMPLETE** (Done in Phase 1 & 3) |
| Phase 6: Trash System | 6-8 hours | ⬜ Not Started |
| Phase 7: Data Migration | 4-6 hours | ✅ **COMPLETE** (Done in Phase 1) |
| Phase 8: State Management | 8-12 hours | ⬜ Not Started |
| Phase 9: UI/UX Polish | 10-15 hours | ⬜ Not Started |
| Phase 10: Testing | 8-12 hours | ⬜ Not Started |
| Phase 11: Documentation | 4-6 hours | ⬜ Not Started |
| **TOTAL** | **78-116 hours** | **~46-69 hours completed** |

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

## Current Status: Phase 3 Complete ✅ - Core MVP Ready!

**Completed:** 
- Phase 1 - Database & Data Models ✅
- Phase 2 - Home Screen (Habit List) ✅
- Phase 3 - Habit Detail Screen (HBTC) ✅
- Phase 4 - Three-Status System ✅
- Phase 5 - Notes System ✅
- Phase 7 - Data Migration ✅

**Next Step:** Phase 6 - Trash & Restore System (Settings screen)

**Last Updated:** November 9, 2025
