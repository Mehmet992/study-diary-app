# SPEC: Local User Preferences & Delta-Sync Timestamp (`shared-preferences`)

## 1. Domain Entities and Contracts

### 1.1 `TimerVisualStyle` (`lib/domain/entities/study_enums.dart`)
- `digital('Digital Timer')`
- `circularRing('Circular Ring Timer')`

### 1.2 `UserPreferences` (`lib/domain/entities/user_preferences.dart`)
Immutable domain entity representing all device-local user preferences and sync metadata stored on the phone via `shared_preferences` (never written to Firestore):
- `SessionType defaultSessionType` (default `SessionType.pomodoro`)
- `int defaultPomodoroSets` (`1..8`, default `4`)
- `bool focusModeEnabled` (default `true` — for dimming/hiding distractions while studying)
- `TimerVisualStyle timerVisualStyle` (default `TimerVisualStyle.digital`)
- `DateTime? lastSyncedAt` (UTC timestamp of the last successful cloud sync, used for incremental `pullSessions(since: lastSyncedAt)` / `pullSubjects(since: lastSyncedAt)` so Firestore only reads new documents)

### 1.3 `UserPreferencesDataSource` (`lib/data/datasources/user_preferences_data_source.dart`)
- Abstract interface:
  - `Future<UserPreferences> getPreferences()`
  - `Future<void> savePreferences(UserPreferences preferences)`
  - `Future<DateTime?> getLastSyncedAt()`
  - `Future<void> setLastSyncedAt(DateTime timestamp)`
- Implementations:
  - `SharedPreferencesUserPreferencesDataSource`: Persists keys (`pref_default_session_type`, `pref_default_pomodoro_sets`, `pref_focus_mode_enabled`, `pref_timer_visual_style`, `pref_last_synced_at`) using `package:shared_preferences/shared_preferences.dart`.
  - `InMemoryUserPreferencesDataSource`: Lightweight in-memory implementation for fast isolated unit/widget tests.

---

## 2. Dependency and Data Flow

```mermaid
graph TD
    SP["SharedPreferences (Device Local Storage)"]
    PrefDS["UserPreferencesDataSource"]
    PrefN["UserPreferencesNotifier (ChangeNotifier)"]
    TimerN["ActiveTimerNotifier"]
    Repo["OfflineFirstStudySessionRepository"]
    Remote["RemoteStudyDataSource (Firestore)"]

    PrefDS --> SP
    PrefN --> PrefDS
    TimerN -->|Loads & saves default mode / sets| PrefDS
    Repo -->|Reads lastSyncedAt before pull & updates after sync| PrefDS
    Repo -->|pullSessions(since: lastSyncedAt)| Remote
```

---

## 3. Atomic Task Checklist

- [x] **Task 1: Domain Entity (`UserPreferences`) & `UserPreferencesDataSource` (`shared_preferences`)**
  - Add `TimerVisualStyle` to `lib/domain/entities/study_enums.dart`.
  - Create `lib/domain/entities/user_preferences.dart` with validation and `copyWith`.
  - Create `lib/data/datasources/user_preferences_data_source.dart` with `SharedPreferencesUserPreferencesDataSource` and `InMemoryUserPreferencesDataSource`.
- [x] **Task 2: Delta-Sync Optimization in `OfflineFirstStudySessionRepository` & Timer Preference Persistence**
  - Update `OfflineFirstStudySessionRepository` to read `lastSyncedAt` from `UserPreferencesDataSource`, pass `since: lastSyncedAt` into `remoteDataSource.pullSubjects(since: ...)` and `remoteDataSource.pullSessions(since: ...)`, and save the new `lastSyncedAt` timestamp after a successful sync.
  - Update `ActiveTimerNotifier` to restore `defaultSessionType` and `defaultPomodoroSets` from `UserPreferencesDataSource` and persist changes when the user selects a study mode or changes Pomodoro target sets.
  - Create `UserPreferencesNotifier` (`lib/presentation/notifiers/user_preferences_notifier.dart`) and wire it into `MultiProvider` in `lib/main.dart`.
- [x] **Task 3: Unit & Widget Tests Verification**
  - Add unit tests in `test/mvp_offline_core_test.dart` verifying `SharedPreferencesUserPreferencesDataSource` persistence, `ActiveTimerNotifier` preference restoration, and `OfflineFirstStudySessionRepository` passing `since: lastSyncedAt` to `RemoteStudyDataSource`.
  - Run `dart analyze` and `flutter test --no-pub`.

---

## 4. Failure Modes and Edge Cases
- **Corrupted or Unknown Preference Values:** If a stored string in `SharedPreferences` is unrecognized or out of range (e.g. Pomodoro sets `< 1` or `> 8`), `SharedPreferencesUserPreferencesDataSource` falls back safely to defaults (`SessionType.pomodoro`, `4` sets, `focusModeEnabled: true`) instead of throwing or crashing at startup.
- **Failed Sync Does Not Advance `lastSyncedAt`:** `lastSyncedAt` in `SharedPreferences` is updated **only** when `syncSessions()` completes without errors, guaranteeing no remote records are skipped if a network error interrupts sync.
