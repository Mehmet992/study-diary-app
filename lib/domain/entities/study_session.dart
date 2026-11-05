import 'package:flutter/foundation.dart';

import 'study_enums.dart';

export 'study_enums.dart';

class StudySessionValidationException implements Exception {
  final String message;
  const StudySessionValidationException(this.message);

  @override
  String toString() => 'StudySessionValidationException: $message';
}

class StudySession {
  final String id;
  final String? userId;
  final String? subjectId;
  final String subject;
  final String topic;
  final String notes;
  final StudyActivityType activityType;
  final SessionType sessionType;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int elapsedSeconds;
  final int pausedSeconds;
  final int pauseCount;
  final int completedPomodoroSets;
  final int? targetPomodoroSets;
  final int? targetDurationMinutes;
  final int? correctCount;
  final int? wrongCount;
  final int? blankCount;
  final List<ReflectionTag> reflectionTags;
  final List<String> topicsToReview;
  final int? focusRating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final SyncStatus syncStatus;

  DateTime get timestamp => startedAt;
  int get durationMinutes =>
      elapsedSeconds <= 0 ? 0 : (elapsedSeconds + 59) ~/ 60;

  int get totalQuestions =>
      (correctCount ?? 0) + (wrongCount ?? 0) + (blankCount ?? 0);

  double? get netScore => totalQuestions == 0
      ? null
      : (correctCount ?? 0) - ((wrongCount ?? 0) * 0.25);

  double? get secondsPerQuestion =>
      totalQuestions == 0 ? null : elapsedSeconds / totalQuestions;

  const StudySession({
    required this.id,
    this.userId,
    this.subjectId,
    required this.subject,
    this.topic = '',
    this.notes = '',
    this.activityType = StudyActivityType.topicStudy,
    this.sessionType = SessionType.freeStudy,
    this.status = SessionStatus.completed,
    required this.startedAt,
    this.endedAt,
    required this.elapsedSeconds,
    this.pausedSeconds = 0,
    this.pauseCount = 0,
    this.completedPomodoroSets = 0,
    this.targetPomodoroSets,
    this.targetDurationMinutes,
    this.correctCount,
    this.wrongCount,
    this.blankCount,
    this.reflectionTags = const <ReflectionTag>[],
    this.topicsToReview = const <String>[],
    this.focusRating,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.localOnly,
  });

  static Never _fail(String msg) => throw StudySessionValidationException(msg);
  static String? _cleanOpt(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();

  static List<String> _cleanTopics(List<String>? raw) {
    if (raw == null || raw.isEmpty) return const <String>[];
    final Set<String> seen = <String>{};
    final List<String> out = <String>[];
    for (final String item in raw) {
      final String trimmed = item.trim();
      if (trimmed.isNotEmpty && seen.add(trimmed.toLowerCase())) {
        out.add(trimmed);
      }
    }
    return List<String>.unmodifiable(out);
  }

  factory StudySession.validated({
    required String id,
    String? userId,
    String? subjectId,
    required String subject,
    String topic = '',
    String notes = '',
    StudyActivityType activityType = StudyActivityType.topicStudy,
    SessionType sessionType = SessionType.freeStudy,
    SessionStatus status = SessionStatus.completed,
    DateTime? startedAt,
    DateTime? timestamp,
    DateTime? endedAt,
    int? elapsedSeconds,
    int? durationMinutes,
    int pausedSeconds = 0,
    int pauseCount = 0,
    int completedPomodoroSets = 0,
    int? targetPomodoroSets,
    int? targetDurationMinutes,
    int? correctCount,
    int? wrongCount,
    int? blankCount,
    List<ReflectionTag>? reflectionTags,
    List<String>? topicsToReview,
    int? focusRating,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool isDeleted = false,
    SyncStatus syncStatus = SyncStatus.localOnly,
  }) {
    final String cleanId = id.trim();
    if (cleanId.isEmpty) _fail('Session ID must not be empty.');
    final String cleanSubject = subject.trim();
    if (cleanSubject.isEmpty) _fail('Subject must not be empty.');
    final DateTime start = startedAt ??
        timestamp ??
        _fail('Session start timestamp must be provided.');

    final int secs;
    if (elapsedSeconds != null) {
      if (elapsedSeconds < 0 ||
          (status == SessionStatus.completed && elapsedSeconds <= 0)) {
        _fail('Elapsed study time must be greater than zero.');
      }
      secs = elapsedSeconds;
    } else if (durationMinutes != null) {
      if (durationMinutes < 0 ||
          (status == SessionStatus.completed && durationMinutes <= 0)) {
        _fail('Duration in minutes must be greater than zero.');
      }
      secs = durationMinutes * 60;
    } else if (status == SessionStatus.completed) {
      _fail('Duration in minutes must be greater than zero.');
    } else {
      secs = 0;
    }

    if (pausedSeconds < 0 || pauseCount < 0) {
      _fail('Pause metrics must not be negative.');
    }
    if (completedPomodoroSets < 0) {
      _fail('Completed Pomodoro sets must not be negative.');
    }
    if (targetPomodoroSets != null && targetPomodoroSets <= 0) {
      _fail('Target Pomodoro sets must be greater than zero.');
    }
    if (targetDurationMinutes != null && targetDurationMinutes <= 0) {
      _fail('Target duration in minutes must be greater than zero.');
    }
    if ((correctCount != null && correctCount < 0) ||
        (wrongCount != null && wrongCount < 0) ||
        (blankCount != null && blankCount < 0)) {
      _fail('Question counts must not be negative.');
    }
    if (focusRating != null && (focusRating < 1 || focusRating > 5)) {
      _fail('Focus rating must be between 1 and 5.');
    }
    if (endedAt != null && endedAt.isBefore(start)) {
      _fail('Session endedAt must not be before startedAt.');
    }

    final DateTime created = createdAt ?? start;
    final DateTime updated = updatedAt ?? (endedAt ?? created);
    if (updated.isBefore(created)) {
      _fail('Session updatedAt must not be before createdAt.');
    }

    final int? resolvedTargetMinutes = targetDurationMinutes ??
        (sessionType == SessionType.pomodoro && targetPomodoroSets != null
            ? targetPomodoroSets * 25
            : sessionType.defaultMinutes);

    return StudySession(
      id: cleanId,
      userId: _cleanOpt(userId),
      subjectId: _cleanOpt(subjectId),
      subject: cleanSubject,
      topic: topic.trim(),
      notes: notes.trim(),
      activityType: activityType,
      sessionType: sessionType,
      status: status,
      startedAt: start,
      endedAt: endedAt,
      elapsedSeconds: secs,
      pausedSeconds: pausedSeconds,
      pauseCount: pauseCount,
      completedPomodoroSets: completedPomodoroSets,
      targetPomodoroSets: targetPomodoroSets,
      targetDurationMinutes: resolvedTargetMinutes,
      correctCount: correctCount,
      wrongCount: wrongCount,
      blankCount: blankCount,
      reflectionTags: reflectionTags == null
          ? const <ReflectionTag>[]
          : List<ReflectionTag>.unmodifiable(reflectionTags.toSet()),
      topicsToReview: _cleanTopics(topicsToReview),
      focusRating: focusRating,
      createdAt: created,
      updatedAt: updated,
      isDeleted: isDeleted,
      syncStatus: syncStatus,
    );
  }

  StudySession copyWith({
    String? id,
    String? userId,
    bool clearUserId = false,
    String? subjectId,
    bool clearSubjectId = false,
    String? subject,
    String? topic,
    String? notes,
    StudyActivityType? activityType,
    SessionType? sessionType,
    SessionStatus? status,
    DateTime? startedAt,
    DateTime? timestamp,
    DateTime? endedAt,
    bool clearEndedAt = false,
    int? elapsedSeconds,
    int? durationMinutes,
    int? pausedSeconds,
    int? pauseCount,
    int? completedPomodoroSets,
    int? targetPomodoroSets,
    bool clearTargetPomodoroSets = false,
    int? targetDurationMinutes,
    bool clearTargetDurationMinutes = false,
    int? correctCount,
    bool clearCorrectCount = false,
    int? wrongCount,
    bool clearWrongCount = false,
    int? blankCount,
    bool clearBlankCount = false,
    List<ReflectionTag>? reflectionTags,
    List<String>? topicsToReview,
    int? focusRating,
    bool clearFocusRating = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    SyncStatus? syncStatus,
  }) => StudySession(
    id: id ?? this.id,
    userId: clearUserId ? null : (userId ?? this.userId),
    subjectId: clearSubjectId ? null : (subjectId ?? this.subjectId),
    subject: subject ?? this.subject,
    topic: topic ?? this.topic,
    notes: notes ?? this.notes,
    activityType: activityType ?? this.activityType,
    sessionType: sessionType ?? this.sessionType,
    status: status ?? this.status,
    startedAt: startedAt ?? timestamp ?? this.startedAt,
    endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
    elapsedSeconds: elapsedSeconds ??
        (durationMinutes != null ? durationMinutes * 60 : this.elapsedSeconds),
    pausedSeconds: pausedSeconds ?? this.pausedSeconds,
    pauseCount: pauseCount ?? this.pauseCount,
    completedPomodoroSets: completedPomodoroSets ?? this.completedPomodoroSets,
    targetPomodoroSets: clearTargetPomodoroSets
        ? null
        : (targetPomodoroSets ?? this.targetPomodoroSets),
    targetDurationMinutes: clearTargetDurationMinutes
        ? null
        : (targetDurationMinutes ?? this.targetDurationMinutes),
    correctCount: clearCorrectCount ? null : (correctCount ?? this.correctCount),
    wrongCount: clearWrongCount ? null : (wrongCount ?? this.wrongCount),
    blankCount: clearBlankCount ? null : (blankCount ?? this.blankCount),
    reflectionTags: reflectionTags != null
        ? List<ReflectionTag>.unmodifiable(reflectionTags.toSet())
        : this.reflectionTags,
    topicsToReview: topicsToReview != null
        ? _cleanTopics(topicsToReview)
        : this.topicsToReview,
    focusRating: clearFocusRating ? null : (focusRating ?? this.focusRating),
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    syncStatus: syncStatus ?? this.syncStatus,
  );

  List<Object?> get _props => <Object?>[
    id,
    userId,
    subjectId,
    subject,
    topic,
    notes,
    activityType,
    sessionType,
    status,
    startedAt,
    endedAt,
    elapsedSeconds,
    pausedSeconds,
    pauseCount,
    completedPomodoroSets,
    targetPomodoroSets,
    targetDurationMinutes,
    correctCount,
    wrongCount,
    blankCount,
    Object.hashAll(reflectionTags),
    Object.hashAll(topicsToReview),
    focusRating,
    createdAt,
    updatedAt,
    isDeleted,
    syncStatus,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StudySession) return false;
    return listEquals(_props, other._props) &&
        listEquals(reflectionTags, other.reflectionTags) &&
        listEquals(topicsToReview, other.topicsToReview);
  }

  @override
  int get hashCode => Object.hashAll(_props);
}

class StudySummary {
  final int totalSeconds;
  final int totalMinutes;
  final int sessionCount;
  final int todayMinutes;
  final int totalPauses;
  final int totalQuestionsSolved;
  final double totalNetScore;
  final List<String> topicsToReview;

  const StudySummary({
    this.totalSeconds = 0,
    required this.totalMinutes,
    required this.sessionCount,
    this.todayMinutes = 0,
    this.totalPauses = 0,
    this.totalQuestionsSolved = 0,
    this.totalNetScore = 0.0,
    this.topicsToReview = const <String>[],
  });

  factory StudySummary.fromSessions(
    List<StudySession> sessions, {
    DateTime? referenceDate,
  }) {
    final DateTime ref = (referenceDate ?? DateTime.now()).toLocal();
    int seconds = 0;
    int minutes = 0;
    int count = 0;
    int today = 0;
    int pauses = 0;
    int questions = 0;
    double net = 0.0;
    final Set<String> seenTopics = <String>{};
    final List<String> reviewTopics = <String>[];

    for (final StudySession s in sessions) {
      if (s.isDeleted || s.status != SessionStatus.completed) continue;
      seconds += s.elapsedSeconds;
      minutes += s.durationMinutes;
      count += 1;
      pauses += s.pauseCount;
      questions += s.totalQuestions;
      if (s.netScore != null) {
        net += s.netScore!;
      }
      for (final String topic in s.topicsToReview) {
        final String trimmed = topic.trim();
        if (trimmed.isNotEmpty && seenTopics.add(trimmed.toLowerCase())) {
          reviewTopics.add(trimmed);
        }
      }
      final DateTime d = s.startedAt.toLocal();
      if (d.year == ref.year && d.month == ref.month && d.day == ref.day) {
        today += s.durationMinutes;
      }
    }
    return StudySummary(
      totalSeconds: seconds,
      totalMinutes: minutes,
      sessionCount: count,
      todayMinutes: today,
      totalPauses: pauses,
      totalQuestionsSolved: questions,
      totalNetScore: net,
      topicsToReview: List<String>.unmodifiable(reviewTopics),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StudySummary &&
          other.totalSeconds == totalSeconds &&
          other.totalMinutes == totalMinutes &&
          other.sessionCount == sessionCount &&
          other.todayMinutes == todayMinutes &&
          other.totalPauses == totalPauses &&
          other.totalQuestionsSolved == totalQuestionsSolved &&
          other.totalNetScore == totalNetScore &&
          listEquals(other.topicsToReview, topicsToReview));

  @override
  int get hashCode => Object.hash(
    totalSeconds,
    totalMinutes,
    sessionCount,
    todayMinutes,
    totalPauses,
    totalQuestionsSolved,
    totalNetScore,
    Object.hashAll(topicsToReview),
  );
}
