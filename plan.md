cat > PHASED_IMPLEMENTATION_PLAN.md <<'EOF'
# Multi-Habit Tracker — Phase-wise Implementation Plan (Detailed)

**Source:** derived and expanded from `plan.md` (user project).  
**Goal:** transform the current "Daily Success Tracker" into a robust, scalable multi-habit tracker with optional timers, multi-session logging, strong migrations, and production-ready build settings.

---

## Executive summary
This plan breaks work into clear phases — foundation (DB + models), UI/UX core screens, data migration, performance & stability, feature enhancements (timer + multi-session), testing, packaging, and release. Each phase includes specific tasks, acceptance criteria, risks, roll-back strategy and commands to run. Prioritise crash- and data-safety fixes first, then performance, then UX polish and packaging.

---

# Phase 1 — Database & Core Data Models (Foundation) ✔️
**Objective:** design robust schema and migration path; ensure no data loss for existing users.

### Tasks
- Finalize schema:
  - `habits` table: `id INTEGER PRIMARY KEY`, `name TEXT`, `createdAt INTEGER`, `isDeleted INTEGER DEFAULT 0`, `deletedAt INTEGER NULL`, `timerEnabled INTEGER DEFAULT 0`, `allowMultipleSessions INTEGER DEFAULT 0`
  - `habit_records` (or `habit_sessions`) table: `id INTEGER PRIMARY KEY`, `habitId INTEGER`, `startTs INTEGER`, `endTs INTEGER NULL`, `status TEXT` (`complete|missed|skipped`), `note TEXT`, `createdAt INTEGER`
- Add indexes: `INDEX(habitId)`, `INDEX(startTs)`, and a composite for rapid day queries.
- Implement migration:
  - Safe `_onUpgrade` with table-exists checks.
  - If `DailyRecords` is present, create default "Daily Success" habit and migrate rows → new `habit_records`.
  - Do not drop old table until migration verified; log counts and only drop on a follow-up version if desired.
- DB helper API:
  - `init()` with versioning and safe upgrade.
  - CRUD for habits and sessions.
  - `getRunningSession(habitId)`, `createSession(startTs, habitId)`, `endSession(sessionId, endTs)`, `getSessionsForDay(habitId, date)`.
- Acceptance criteria:
  - Fresh install creates v2 schema.
  - Upgrade path converts old data without loss.
  - Unit tests for migration + CRUD.

### Commands / Verification
- Run unit migration tests `flutter test test/migrations_test.dart`.
- Manually inspect DB after upgrade using `sqlite3` or `adb shell` for device DB.

---

# Phase 2 — State Management & Providers ✔️
**Objective:** centralize data and eliminate N+1 queries that harm startup time.

### Tasks
- Implement `HabitProvider` (ChangeNotifier) API:
  - Methods: `loadAllHabits()`, `loadHabitsWithStreaks()`, `startTimer(habitId)`, `pauseTimer(habitId)`, `stopTimer(habitId)`, `toggleMultiSession(habitId)`, `getSessionsForDay(habitId, date)`.
  - Internal cache structures to prevent repeated DB hits (`_habitsCache`, `_streakCache`, `_statsCache`).
  - Persist in-progress session map: on app start, provider checks DB for rows with `endTs IS NULL` and restores running timers.
- Ensure provider initialization is awaited in `main()` before `runApp` (or use a splash/loading screen while `await provider.init()`).
- Avoid `FutureBuilder` per list item — compute aggregates in provider and expose ready-to-bind lists.

### Acceptance criteria
- Home screen builds from provider caches with a single DB call for aggregated data.
- No per-item DB queries on first frame.
- Tests for provider caching correctness.

---

# Phase 3 — Home Screen & Habit List (Performance + UX) ✔️
**Objective:** make core flows discoverable, fast, and scalable.

### Tasks
- Replace per-item `FutureBuilder` with provider-bound list.
- Show high-level quick actions on tiles:
  - "Mark done" (single mode), "Start timer" (if timer enabled), "Quick add session" (multi-mode).
- Add visible streak and small sparkline (optional) to tiles.
- Add empty-state screen with CTA to "Add first habit" and short micro-tutorial.
- Acceptance:
  - Cold-start first frame < 2–3s on mid-range device.
  - Scrolling performance 60fps with 100+ habits.

---

# Phase 4 — Habit Detail Screen (HBTC) & Calendar ✔️ (Completed)
**Objective:** clear, single place for habit sessions, calendar editing, and stats.

### Tasks
- Calendar:
  - TableCalendar with custom day builders: complete/missed/skipped.
  - Day tap opens bottom sheet for session editing + notes.
- Timer widget:
  - Optional control: start/pause/stop.
  - Visual live duration. When started, create a session row with `startTs`; on stop update `endTs`.
- Multi-session toggle:
  - In habit settings toggle between single-daily vs multi-session.
  - UI adapts: single mode shows one completion toggle; multi-mode shows list of sessions with start/stop and manual add session.
- Acceptance:
  - Persisted sessions on app restart; lasted running timers recovered and show correct duration.
  - Switching modes keeps data — in single→multi transform last daily record into single session or leave as-is with a mapped conversion.

---

# Phase 5 — Timer & Multi-Session Feature (Critical UX) ✔️ (Completed)
**Objective:** build optional timer per habit that persists across kills and reboots (best-effort).

### Design constraints
- No persistent background services. Timer persistence achieved by storing `startTs` and computing `now - startTs`.
- If device reboots, timer is considered paused; note this limitation in docs.

### Tasks ✔️
- DB: `habit_sessions` table supports sessions with `startTs`, `endTs`. ✔️
- Provider: ✔️
  - `startTimer(habitId)` → creates session row with `endTs = NULL`. ✔️
  - `pauseTimer(habitId)` → set a paused flag in-memory and update DB if needed. ✔️
  - `resumeTimer(habitId)` → clear pause flag and adjust duration tracking. ✔️
  - `stopTimer(habitId, {endTime})` → sets `endTs` to timestamp (or custom), calculates duration. ✔️
  - `restoreRunningSessions()` on provider init: query for `endTs IS NULL`, rehydrate in-memory timers. ✔️
  - Anomaly detection: `hasTimerAnomaly(habitId)` detects sessions >24h and warns user. ✔️
- UI: ✔️
  - Timer button with states: Start / Pause / Resume / Stop. ✔️
  - Show "Timer restored after restart" banner if session exists and app restarted. ✔️
  - Display per-day session list with start/end times and durations. ✔️
  - Anomaly warning UI with "Adjust & stop timer" button to pick custom end time. ✔️
- Edge cases: ✔️
  - Device off: record startTs and on resume compute actual duration; if device/time changed drastically, show warning and let user edit end time. ✔️
  - Manual adjustment: user can pick date/time for session end via date+time pickers. ✔️
- Acceptance: ✔️
  - Start -> kill app -> reopen -> timer still counts elapsed (computed). ✔️
  - Start -> reboot -> open -> session exists but note that actual runtime during reboot is not counted (documented). ✔️
  - Unit tests for duration calc ±1s tolerance when not killed. ✔️
  - Widget test validates timer UI controls and state management. ✔️

### Implementation Details
- **Provider enhancements:**
  - `_restoredSessionHabits` set tracks habits with restored sessions
  - `_sessionAnomalyHabits` set tracks habits with long-running sessions (>24h)
  - `elapsedDurationFor(habitId, referenceMillis)` computes elapsed time accounting for pauses
  - Pause tracking via `_pausedAt` and `_accumulatedPauseDuration` maps
- **Habit Detail Screen:**
  - Periodic timer updates every second for live elapsed display
  - Timer control card with enable/multi-session toggles
  - Restored session banner with informational text and anomaly warnings
  - Session list per selected day showing all completed/running sessions
  - Manual end-time adjustment workflow using date and time pickers
- **Testing:**
  - `test/widget/habit_detail_timer_ui_test.dart` validates timer controls with in-memory manager
  - Passes all assertions for timer enable/start/display/disable flows

---

# Phase 6 — Migration Safety & Backwards Compatibility ✔️
**Objective:** guarantee no user data loss and safe rollbacks.

### Tasks
- Implement safe `_onUpgrade`:
  - If missing legacy tables, skip migration with logged reason.
  - For migration always create backups: copy legacy table to `backup_dailyrecords_{ts}` before transforming.
- Provide an "admin" dev flag to run migrations in a dry-run mode that writes a log of actions to file.
- Acceptance:
  - Migration dry-run produces a log with row counts.
  - Real migration produces a `migration_report.json` in app storage.

---

# Phase 7 — Performance, Build & Packaging ✔️
**Objective:** reduce APK size and eliminate install-time space problems.

### Tasks
- Remove heavy runtime font fetching (`google_fonts`) or set `GoogleFonts.config.allowRuntimeFetching = false` and bundle required fonts in assets.
- Use ABI splits for release:
  - `splits { abi { enable true; reset(); include 'armeabi-v7a','arm64-v8a'; } }`
- Enable R8/shrinkResources with targeted keep rules (avoid missing Play Core references).
- Analyze size: `flutter build apk --analyze-size --release` and inspect `build/app/outputs/*/size-analysis`.
- Acceptance:
  - Per-ABI release APK < 15 MB (objective, depends on native libs).
  - Install unpacks without requiring >200–300MB free space.

### Commands
- `flutter clean && flutter build apk --release --split-per-abi`
- `flutter build apk --analyze-size --release`
- Inspect size report in `build/app/outputs/size-analysis/`.

---

# Phase 8 — Stability & Crash Handling ✔️
**Objective:** ensure uncaught async errors do not cause silent crashes.

### Tasks
- Wrap `main()` with `runZonedGuarded` and set `FlutterError.onError` to forward errors to logger (and optionally crash reporting).
- Protect DB init with try/catch; on DB failure show a friendly error screen and allow user to export DB for debugging.
- Replace `context.read(...).load...()` in `initState()` with provider async lifecycle managed calls where errors are caught and surfaced.
- Acceptance: No silent process kills; all fatal errors produce a visible error screen and logged stack traces.

---

# Phase 9 — UI/UX Polish & Onboarding (Design) ✔️
**Objective:** remove scatter, improve discoverability and new-user success.

### Onboarding microflow (first-run):
1. Splash → short 3-step coach marks:
   - Step 1: "Add your first habit" (CTA).
   - Step 2: "Timer & sessions" (explain optionality).
   - Step 3: "Quick log" (how single vs multi-mode works).
2. Contextual tooltips on first use for Habit Detail screen:
   - Short animated highlight for Timer widget and Multi-session toggle.
3. Settings & help:
   - "How it works" short page describing persistent timer caveats (reboots) and multi-session behavior.
4. Visual updates:
   - Clear hierarchical typography.
   - Tile affordances for quick actions.
   - Use micro-animations for successful actions (Snackbars + haptic).

### Acceptance
- 80% of test users can add a habit and start a timer within 30s of opening the app for the first time.

---

# Phase 10 — Accessibility, Tests & QA ✔️
**Objective:** ensure robust code coverage and accessibility.

### Tasks
- Add semantic labels for screen readers.
- Unit tests:
  - Migration tests, DB CRUD, `HabitProvider` timer APIs.
- Widget tests:
  - Home screen, habit detail, day bottom sheet.
- Integration tests:
  - Full flow: create habit → start timer → stop → verify session in DB.
- Manual QA: test on multiple Android versions (Android 10–14) and ABI variants.

### Commands
- Run unit tests: `flutter test`
- Run integration: `flutter drive --target=test_driver/app.dart` (if configured)

---

# Phase 11 — Release & Post-release Checklist ✔️
**Objective:** release with confidence.

### Release checklist
- Bump version in `pubspec.yaml`.
- Validate proguard rules and ensure R8 passes consistently.
- Build per-ABI release APKs and test install on physical devices.
- Smoke tests: start, create session, restart, stop, export DB.
- Prepare Play Store assets and release notes.

---

# Risks, Mitigations & Rollback Strategy
- **Risk:** Migration bug causing data loss.  
  **Mitigation:** backup legacy table, provide dry-run and export; run migration on small cohort (beta) first; provide rollback that restores backup table.
- **Risk:** Timer persistence ambiguity after reboot.  
  **Mitigation:** surface clear UX note and provide manual edit for session end times.
- **Risk:** R8/ProGuard missing classes.  
  **Mitigation:** include play-core dependency if needed or add targeted keep rules; always test `flutter build apk --release`.
- **Rollback:** Keep DB backups and instrument a migration flag allowing rollback to previous schema + restore.

---

# Deliverables per phase (artifact checklist)
- SQL migration scripts & `database_helper.dart` changes
- `lib/models/habit.dart`, `habit_session.dart`
- `lib/providers/habit_provider.dart`
- Updated `lib/screens/*` files (home, habit_detail, settings, trash)
- Unit & widget tests under `test/`
- Size analysis JSON from `flutter build --analyze-size`
- Migration report `migration_report.json` on device after upgrade

---

# Estimated timeline & effort (recommended sprints)
- Sprint 1 (1 week): Phase 1 + Phase 2 (DB + Provider + tests)
- Sprint 2 (1 week): Phase 3 + Phase 4 (Home + Detail + Calendar)
- Sprint 3 (1 week): Phase 5 + Phase 6 (Timer + Migration safety)
- Sprint 4 (1 week): Phase 7 + Phase 8 (Performance + Stability)
- Sprint 5 (1 week): Phase 9 + Phase 10 (UX polish + QA)
- Release prep (3 days): Phase 11

---

# How to use this file
- Paste it into repository root as `PHASED_IMPLEMENTATION_PLAN.md`.
- Use each phase as a checklist for PRs.
- Attach migration tests to each DB change PR.

---

## Appendix — Useful commands (copy/paste)
```bash
# Clean + build per-ABI release:
flutter clean
flutter pub get
flutter build apk --release --split-per-abi

# Analyze size:
flutter build apk --analyze-size --release

# Run unit tests:
flutter test

# Capture device logs:
adb logcat -c
adb logcat > crash_log.txt &

# Show Gradle dependency graph (android):
cd android && ./gradlew :app:dependencies --configuration releaseRuntimeClasspath
