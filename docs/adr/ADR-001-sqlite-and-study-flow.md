---
title: "SQLite Offline-First Storage, Split Notifiers, and Post-Session AI Reflection Flow"
date: "2026-11-05"
status: "Accepted"
tags:
  - architecture
  - flutter
  - sqlite
  - state-management
  - study-flow
---

## Context and Problem Statement
`study_diary_app` is a mobile (Android & iOS) study companion and diary designed for students preparing for competitive exams such as YKS. We needed a sustainable, production-ready tech stack and user flow that:
1. Works 100% offline on the device while keeping future cloud sync (Firebase Firestore) near $0 in read/write costs.
2. Eliminates upfront form-filling friction before starting a study timer.
3. Supports the student psychologically during Pomodoro breaks without interrupting their focus with note-taking after every 25-minute set.
4. Captures structured post-session data (questions solved, correct/wrong/blank counts, Net score, feeling tags, and topics to review) suitable for future AI coaching.

## Decision Drivers
- **Cost & Offline Reliability:** Reading from cloud databases on every screen open is expensive at scale; a local relational database must serve as the primary UI source of truth.
- **Developer Control & Maintainability:** State management and database queries should be transparent, fast to compile (no code-generation wait times), and split into focused classes.
- **Student Psychology & Zero Friction:** Starting a timer must take 1 tap (`Pomodoro`, `Free Study`, or `1 Hour Study`), with notes and question metrics collected only once the full session ends.

## Considered Options
1. **`sqflite` (Local SQLite) + `ChangeNotifier`/`Provider` (Split Notifiers) + Post-Session Reflection Flow (Chosen)**
2. **Custom JSON file storage + single monolithic `StudySessionNotifier` + upfront form inputs (Rejected — previous subagent design)**
3. **`drift` ORM + `flutter_bloc` + direct Firestore reads (Rejected — heavy code generation & higher cloud read costs)**

## Decision Outcome
Chosen option: **"`sqflite` + Split `ChangeNotifier`/`Provider` + Post-Session Reflection Flow"**, because:
- [`SqliteLocalStudyDataSource`](../../lib/data/datasources/sqlite_local_study_data_source.dart) stores all sessions and subjects locally in SQLite (`study_diary.db`) with `sync_status` tracking, ensuring 0 cloud reads during normal app browsing and preserving data offline.
- Splitting state into [`ActiveTimerNotifier`](../../lib/presentation/notifiers/active_timer_notifier.dart) and [`StudyDiaryNotifier`](../../lib/presentation/notifiers/study_diary_notifier.dart) via `Provider` keeps timer ticks isolated from diary persistence logic.
- Moving Subject, Topic, Question Solving metrics (`Correct`, `Wrong`, `Blank`, auto-calculated `Net`), `ReflectionTag` signals, and `topicsToReview` to [`PostSessionReflectionCard`](../../lib/presentation/widgets/post_session_reflection_sheet.dart) at the end of the session keeps study start friction-free while producing structured data for AI guidance.

### Positive Consequences
- Instant offline reads/writes on Android and iOS with standard SQL indexes (`started_at DESC`, `sync_status`).
- Zero `build_runner` code generation overhead.
- Structured YKS metrics (`netScore`, `secondsPerQuestion`, `reflectionTags`, `topicsToReview`) ready for AI coaching and Dashboard review checklists.

### Negative Consequences / Accepted Technical Debt
- Raw SQL column names in `SqliteLocalStudyDataSource` must be kept in sync with `StudySessionModel.toSqlMap()` / `fromSqlMap()`, which we enforce via automated SQLite round-trip unit tests.
