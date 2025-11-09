# Notes Feature - Testing Checklist

**Date:** November 9, 2025  
**Feature:** Phase 5.3 - Notes Viewing & Search  
**Status:** Ready for Testing ✅

---

## Pre-Test Setup

### 1. Ensure Test Data Exists
- [ ] At least 2-3 habits created
- [ ] Each habit has 5-10 records
- [ ] Mix of all three statuses (Complete/Missed/Skipped)
- [ ] At least 5-7 days with notes
- [ ] Some days without notes for comparison
- [ ] Notes of varying lengths (short & long)

### 2. App Running
- [x] App launched successfully
- [x] No compilation errors
- [x] Emulator/device ready

---

## Test Suite 1: Basic Note Functionality

### Test 1.1: Add Notes
**Steps:**
1. Open any habit from home screen
2. Tap any day in the calendar
3. Select a status (Complete/Missed/Skipped)
4. Type a note in the text field
5. Tap "Save"

**Expected Results:**
- [ ] Note saves successfully
- [ ] White dot (⚪) appears on that day in calendar
- [ ] Tapping day again shows saved note
- [ ] Note persists after app restart

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 1.2: Edit Existing Notes
**Steps:**
1. Tap a day with existing note (has white dot)
2. Modify the note text
3. Tap "Save"

**Expected Results:**
- [ ] Note updates successfully
- [ ] White dot remains on calendar
- [ ] New note text displays correctly

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 1.3: Delete Notes
**Steps:**
1. Tap a day with a note
2. Tap "Delete" button
3. Confirm deletion

**Expected Results:**
- [ ] Note is deleted
- [ ] White dot disappears from calendar
- [ ] Record is removed from database

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

## Test Suite 2: Notes List Screen

### Test 2.1: Access from Home Screen
**Steps:**
1. From home screen, tap notes icon (📋) in app bar
2. Observe the notes list

**Expected Results:**
- [ ] NotesListScreen opens
- [ ] Shows "All Notes" in app bar
- [ ] Displays notes from ALL habits
- [ ] Notes sorted by date (newest first)
- [ ] Each card shows: habit name, date, status icon, note content

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 2.2: Access from Habit Detail Screen
**Steps:**
1. Open any habit
2. Tap notes icon (📋) in app bar
3. Observe the notes list

**Expected Results:**
- [ ] NotesListScreen opens
- [ ] Shows "Habit Notes" in app bar
- [ ] Displays notes ONLY for that habit
- [ ] Notes sorted by date (newest first)

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 2.3: Empty State
**Steps:**
1. Create a new habit with no notes
2. Open that habit's notes list

**Expected Results:**
- [ ] Shows empty state message
- [ ] Message: "No notes yet"
- [ ] Guidance text displayed

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 2.4: Note Card Display
**Steps:**
1. Open notes list with existing notes
2. Examine each note card

**Expected Results:**
- [ ] Status icon shows correct color:
  - Green for Complete ✅
  - Red for Missed ❌
  - Yellow for Skipped ➖
- [ ] Habit name displayed prominently
- [ ] Date shows "Today" for today's notes
- [ ] Date shows formatted date for other days
- [ ] Note content in highlighted box
- [ ] 📝 emoji shown with note

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

## Test Suite 3: Search Functionality

### Test 3.1: Search Note Content
**Steps:**
1. Open notes list (all notes)
2. Type a keyword in search bar (e.g., "great")
3. Observe results

**Expected Results:**
- [ ] Results filter in real-time
- [ ] Only notes containing "great" are shown
- [ ] Search is case-insensitive
- [ ] Clear button (❌) appears

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 3.2: Search Habit Name
**Steps:**
1. Open notes list (all notes)
2. Type a habit name in search bar
3. Observe results

**Expected Results:**
- [ ] Results filter to show notes from that habit
- [ ] All notes from matching habits displayed
- [ ] Works even if habit name not in note content

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 3.3: Clear Search
**Steps:**
1. Type something in search bar
2. Click clear button (❌)

**Expected Results:**
- [ ] Search text clears
- [ ] All notes reappear
- [ ] Clear button disappears

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 3.4: No Search Results
**Steps:**
1. Type nonsense text that won't match anything
2. Observe results

**Expected Results:**
- [ ] Shows empty state
- [ ] Message: "No notes match your filters"
- [ ] Guidance to adjust search/filters

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

## Test Suite 4: Filter Functionality

### Test 4.1: Open/Close Filter Panel
**Steps:**
1. Tap filter icon in app bar
2. Observe filter panel
3. Tap filter icon again

**Expected Results:**
- [ ] Filter panel appears below search bar
- [ ] Shows status filters, habit filters (if all notes), date range
- [ ] Filter icon changes appearance (filled/outlined)
- [ ] Panel toggles on/off correctly

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 4.2: Status Filter - Single Selection
**Steps:**
1. Open filter panel
2. Deselect "Missed" and "Skipped"
3. Keep only "Complete" selected
4. Observe results

**Expected Results:**
- [ ] Only notes with Complete status shown
- [ ] All Complete notes visible
- [ ] Missed and Skipped notes hidden

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 4.3: Status Filter - Multiple Selection
**Steps:**
1. Select Complete and Missed
2. Deselect Skipped
3. Observe results

**Expected Results:**
- [ ] Shows Complete and Missed notes
- [ ] Skipped notes hidden
- [ ] Both status types visible

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 4.4: Status Filter - All Deselected
**Steps:**
1. Deselect all status filters
2. Observe results

**Expected Results:**
- [ ] No notes shown (all filtered out)
- [ ] Empty state with filter message

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 4.5: Habit Filter (All Notes View Only)
**Steps:**
1. Open notes list from home screen
2. Open filter panel
3. Deselect one or more habits
4. Observe results

**Expected Results:**
- [ ] Only notes from selected habits shown
- [ ] Deselected habits' notes hidden
- [ ] Multi-select works correctly
- [ ] Filter chips toggle on/off

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 4.6: Date Range Filter
**Steps:**
1. Open filter panel
2. Tap "Select Date Range"
3. Choose start and end dates
4. Observe results

**Expected Results:**
- [ ] Date picker dialog opens
- [ ] Can select date range
- [ ] Only notes within range shown
- [ ] Button shows selected range
- [ ] "Clear" button appears

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 4.7: Clear Date Range
**Steps:**
1. After setting a date range
2. Tap "Clear" button
3. Observe results

**Expected Results:**
- [ ] Date range clears
- [ ] All date notes reappear
- [ ] Button returns to "Select Date Range"

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 4.8: Combined Filters
**Steps:**
1. Set multiple filters:
   - Search: "workout"
   - Status: Only Complete
   - Habit: One specific habit
   - Date: Last 7 days
2. Observe results

**Expected Results:**
- [ ] All filters work together (AND logic)
- [ ] Only notes matching ALL criteria shown
- [ ] Filters don't conflict

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

## Test Suite 5: Navigation

### Test 5.1: Tap Note Card
**Steps:**
1. From notes list, tap any note card
2. Observe navigation

**Expected Results:**
- [ ] Navigates to habit detail screen
- [ ] Correct habit opens
- [ ] Calendar displays
- [ ] Can tap the day to edit note

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 5.2: Back Navigation
**Steps:**
1. Open notes list
2. Tap device/emulator back button
3. Observe navigation

**Expected Results:**
- [ ] Returns to previous screen
- [ ] If from home → returns to home
- [ ] If from habit → returns to habit detail

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 5.3: Refresh After Navigation
**Steps:**
1. Open notes list
2. Tap a note card → Navigate to habit detail
3. Edit/delete the note
4. Go back to notes list
5. Observe updates

**Expected Results:**
- [ ] Notes list refreshes
- [ ] Changes reflected immediately
- [ ] Edited notes show new content
- [ ] Deleted notes removed from list

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

## Test Suite 6: UI/UX

### Test 6.1: Loading States
**Steps:**
1. Open notes list
2. Observe initial load

**Expected Results:**
- [ ] Loading spinner shows while fetching
- [ ] Smooth transition to content
- [ ] No flashing or jarring changes

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 6.2: Scrolling
**Steps:**
1. Open notes list with many notes
2. Scroll up and down
3. Observe behavior

**Expected Results:**
- [ ] Smooth scrolling
- [ ] Search bar stays at top
- [ ] Filter panel scrolls with content
- [ ] No performance issues

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 6.3: Screen Rotation
**Steps:**
1. Open notes list
2. Rotate device/emulator
3. Observe layout

**Expected Results:**
- [ ] Layout adapts to orientation
- [ ] No data loss
- [ ] Filters/search preserved
- [ ] UI remains usable

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 6.4: Long Note Content
**Steps:**
1. Create note with 200 characters
2. View in notes list
3. Observe display

**Expected Results:**
- [ ] Full note displayed
- [ ] No truncation or overflow
- [ ] Readable formatting
- [ ] Card expands as needed

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 6.5: Multiple Habits with Same Name
**Steps:**
1. If possible, test with habits having similar names
2. Search for common term
3. Observe results

**Expected Results:**
- [ ] All matching habits shown
- [ ] Can distinguish between habits
- [ ] Filter works correctly

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

## Test Suite 7: Edge Cases

### Test 7.1: Very Long Habit Name
**Steps:**
1. Create habit with long name
2. Add note to it
3. View in notes list

**Expected Results:**
- [ ] Name doesn't overflow
- [ ] Card layout remains clean
- [ ] Readable display

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 7.2: Special Characters in Notes
**Steps:**
1. Add note with special characters (emoji, symbols)
2. View in notes list
3. Search for special characters

**Expected Results:**
- [ ] Special characters display correctly
- [ ] Search handles special characters
- [ ] No crashes or errors

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 7.3: Today's Notes
**Steps:**
1. Add note to today's date
2. View in notes list
3. Check date display

**Expected Results:**
- [ ] Shows "Today" instead of date
- [ ] Correct status and content
- [ ] Appears at top of list (most recent)

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 7.4: Old Notes (30+ days)
**Steps:**
1. If available, check notes from 30+ days ago
2. View in notes list
3. Apply date filters

**Expected Results:**
- [ ] Old notes display correctly
- [ ] Date formatted properly
- [ ] Can filter by old date ranges

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 7.5: Rapid Filter Changes
**Steps:**
1. Quickly toggle multiple filters on/off
2. Type and clear search rapidly
3. Observe behavior

**Expected Results:**
- [ ] No crashes
- [ ] UI remains responsive
- [ ] Results update correctly
- [ ] No lag or freezing

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

## Test Suite 8: Data Persistence

### Test 8.1: App Restart
**Steps:**
1. View notes list
2. Close app completely
3. Reopen app
4. Navigate to notes list

**Expected Results:**
- [ ] All notes still present
- [ ] No data loss
- [ ] Correct sorting maintained

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 8.2: Create and Immediately View
**Steps:**
1. Create new note
2. Immediately open notes list
3. Check if note appears

**Expected Results:**
- [ ] New note appears in list
- [ ] Correct data displayed
- [ ] No delay in showing

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

## Test Suite 9: Performance

### Test 9.1: Large Dataset
**Steps:**
1. Create 50+ notes across multiple habits
2. Open notes list
3. Test search and filters

**Expected Results:**
- [ ] Opens quickly (<2 seconds)
- [ ] Smooth scrolling
- [ ] Search performs well
- [ ] Filters apply quickly

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 9.2: Memory Usage
**Steps:**
1. Open notes list
2. Navigate back and forth multiple times
3. Check for memory leaks

**Expected Results:**
- [ ] No memory leaks
- [ ] App remains responsive
- [ ] No slowdown over time

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

## Test Suite 10: Integration

### Test 10.1: With Habit Deletion
**Steps:**
1. View notes list
2. Go back and delete a habit
3. Return to notes list

**Expected Results:**
- [ ] Notes from deleted habit removed
- [ ] No orphaned notes
- [ ] No errors

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

### Test 10.2: With Streak Calculation
**Steps:**
1. View habit detail with streak
2. Open notes list
3. Verify status matches streak data

**Expected Results:**
- [ ] Status icons match actual records
- [ ] Streak calculation unaffected
- [ ] Data consistency maintained

**Status:** ⬜ Not Tested | ✅ Passed | ❌ Failed

---

## Manual Testing Checklist

### Quick Test (5-10 minutes)
- [ ] Add 3 notes to different habits
- [ ] Open notes list from home screen
- [ ] Search for a keyword
- [ ] Apply one filter (e.g., Complete only)
- [ ] Tap a note card and navigate to habit
- [ ] Verify note indicator on calendar

### Medium Test (20-30 minutes)
- [ ] Complete all tests in Suite 1-5
- [ ] Test all filter combinations
- [ ] Test search with various inputs
- [ ] Navigate between all screens
- [ ] Check UI on different scenarios

### Full Test (1-2 hours)
- [ ] Complete ALL test suites
- [ ] Document any issues found
- [ ] Test edge cases thoroughly
- [ ] Performance testing with large dataset
- [ ] Full regression testing

---

## Issues Found

### Issue Template:
**Issue #:** 
**Test Suite:** 
**Test Case:** 
**Severity:** Low | Medium | High | Critical
**Description:** 
**Steps to Reproduce:** 
**Expected:** 
**Actual:** 
**Screenshots:** 
**Status:** Open | In Progress | Resolved

---

## Test Summary

**Total Tests:** 60+
**Tests Passed:** ___
**Tests Failed:** ___
**Tests Skipped:** ___
**Pass Rate:** ___%

**Critical Issues:** ___
**High Priority Issues:** ___
**Medium Priority Issues:** ___
**Low Priority Issues:** ___

---

## Sign-Off

**Tested By:** _______________
**Date:** November 9, 2025
**Build Version:** 1.0.0
**Overall Status:** ⬜ Pass | ⬜ Pass with Issues | ⬜ Fail

**Notes:**


**Approved By:** _______________
**Date:** _______________

---

## Next Steps

After testing completion:
- [ ] Fix all critical and high priority issues
- [ ] Re-test failed test cases
- [ ] Update documentation if needed
- [ ] Consider UI/UX improvements
- [ ] Plan for Phase 6 (Trash & Restore)

---

**End of Test Plan**
