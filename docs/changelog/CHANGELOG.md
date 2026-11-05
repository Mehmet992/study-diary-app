# Changelog

All notable changes to `study_diary_app` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **SQLite Local Persistence (`sqflite`):** Implemented `SqliteLocalStudyDataSource` (`lib/data/datasources/sqlite_local_study_data_source.dart`) with indexed `study_sessions` and `study_subjects` tables, transactional batch upserts, and SQL serialization (`toSqlMap` / `fromSqlMap`) in `StudySessionModel` and `StudySubjectModel`.
- **Offline-First Sync Foundation:** Retained `OfflineFirstStudySessionRepository` (`lib/data/repositories/offline_first_study_session_repository.dart`) with `SyncStatus` tracking (`localOnly`, `pendingSync`, `synced`, `pendingDelete`, `syncFailed`) ready for cost-safe Firebase Firestore delta sync.
- **3 Distraction-Free Study Modes:** Configured `SessionType` (`lib/domain/entities/study_enums.dart`) for `pomodoro` (25m study / 5m break sets, configurable 1–8 sets), `freeStudy` (count-up stopwatch), and `oneHour` (strict 60m countdown).
- **AI-Ready Post-Session Reflection Domain & UI:**
  - Added `StudyActivityType` (`topicStudy`, `questionSolving`, `mockExam`), `ReflectionTag` (`understoodWell`, `needMorePractice`, `carelessMistakes`, `timePressure`, `conceptGap`), and `CompanionMood` (`idle`, `studying`, `breakRest`, `finalSetCheer`, `proudCelebration`).
  - Enriched `StudySession` and `StudySummary` (`lib/domain/entities/study_session.dart`) with `correctCount`, `wrongCount`, `blankCount`, computed `totalQuestions`, YKS `netScore` (`correct - wrong * 0.25`), `secondsPerQuestion`, `reflectionTags`, and `topicsToReview`.
  - Built `PostSessionReflectionCard` (`lib/presentation/widgets/post_session_reflection_sheet.dart`) for fast post-study logging and manual session entry.
- **Psychological Companion Break Flow:** Built `CompanionMascotCard` (`lib/presentation/widgets/companion_mascot_card.dart`) and Pomodoro break state transitions in `ActiveTimerNotifier` (`lib/presentation/notifiers/active_timer_notifier.dart`) delivering context-aware encouragement messages between sets and upon completion.
- **Split State Management (`Provider`):** Created focused `ActiveTimerNotifier` and `StudyDiaryNotifier` (`lib/presentation/notifiers/study_diary_notifier.dart`) provided via `MultiProvider` in `lib/main.dart`, with UUIDv4 session IDs (`uuid`) and review-topic resolution (`markReviewTopicResolved`).
- **3-Tab Mobile Navigation Shell:** Updated `MainShellScreen` (`lib/presentation/screens/main_shell_screen.dart`) to host `DashboardScreen` (stats, Net score, and interactive "Topics to Look After" checklist), `StudyPageScreen` (distraction-free timer & companion), and `DiaryScreen` (`lib/presentation/screens/diary_screen.dart` with `intl` formatted history cards).

### Removed
- Removed legacy `JsonFileLocalStudyDataSource`, monolithic `StudySessionNotifier`, upfront pre-study text inputs on `StudyPageScreen`, unused desktop/web platform directories (`linux/`, `windows/`, `macos/`, `web/`), and autonomous background subagent definitions.
